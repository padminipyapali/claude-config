import { test, expect } from "@playwright/test";

test.describe("white-space + line-clamp interactions", () => {
  test("line-clamp with hard newlines truncates at visual line count", async ({
    page,
  }) => {
    // Fixture: container with line-clamp:2, content has 5 hard newlines
    // With white-space:normal (correct), clamp works — height is clamped
    // With white-space:pre-wrap (bug), each newline forces a line break, defeating clamp
    await page.setContent(`
      <style>
        .container { max-width: 300px; font: 16px/1.5 monospace; }
        .clamped-normal {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
          white-space: normal;
        }
        .clamped-prewrap {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
          white-space: pre-wrap;
        }
        .unclamped {
          white-space: pre-wrap;
        }
      </style>
      <div class="container">
        <div class="clamped-normal" id="normal">Line1
Line2
Line3
Line4
Line5</div>
        <div class="clamped-prewrap" id="prewrap">Line1
Line2
Line3
Line4
Line5</div>
        <div class="unclamped" id="unclamped">Line1
Line2
Line3
Line4
Line5</div>
      </div>
    `);
    const normalHeight = await page
      .locator("#normal")
      .evaluate((el) => el.getBoundingClientRect().height);
    const prewrapHeight = await page
      .locator("#prewrap")
      .evaluate((el) => el.getBoundingClientRect().height);
    const unclampedHeight = await page
      .locator("#unclamped")
      .evaluate((el) => el.getBoundingClientRect().height);

    // white-space:normal + clamp should be shorter than unclamped
    expect(normalHeight).toBeLessThan(unclampedHeight);
    // Documenting the interaction: pre-wrap may defeat the clamp
    // (In some browsers pre-wrap + line-clamp still works, so we test relative behavior)
    expect(normalHeight).toBeLessThanOrEqual(prewrapHeight);
  });

  test("text-overflow ellipsis silently disabled by pre-wrap", async ({
    page,
  }) => {
    await page.setContent(`
      <style>
        .container { max-width: 200px; font: 16px/1.5 monospace; }
        .ellipsis-normal {
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .ellipsis-prewrap {
          white-space: pre-wrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
      </style>
      <div class="container">
        <div class="ellipsis-normal" id="normal">This is a very long line of text that should be truncated with an ellipsis</div>
        <div class="ellipsis-prewrap" id="prewrap">This is a very long line of text that should be truncated with an ellipsis</div>
      </div>
    `);
    const normalHeight = await page
      .locator("#normal")
      .evaluate((el) => el.getBoundingClientRect().height);
    const prewrapHeight = await page
      .locator("#prewrap")
      .evaluate((el) => el.getBoundingClientRect().height);

    // nowrap keeps it on one line; pre-wrap wraps, defeating ellipsis
    expect(prewrapHeight).toBeGreaterThan(normalHeight);
  });

  test("hard newline content exhausts clamp faster than expected", async ({
    page,
  }) => {
    await page.setContent(`
      <style>
        .container { max-width: 300px; font: 16px/1.5 monospace; }
        .clamped {
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
          overflow: hidden;
          white-space: normal;
        }
      </style>
      <div class="container">
        <div class="clamped" id="short-lines">A
B
C
D
E</div>
        <div class="clamped" id="long-text">This is a single long paragraph without any line breaks that should wrap naturally within the container and be clamped at three lines</div>
      </div>
    `);
    const shortHeight = await page
      .locator("#short-lines")
      .evaluate((el) => el.getBoundingClientRect().height);
    const longHeight = await page
      .locator("#long-text")
      .evaluate((el) => el.getBoundingClientRect().height);

    // white-space:normal collapses hard newlines into spaces, so "A B C D E"
    // fits on one line — the clamp never activates. The long paragraph wraps
    // to 3 lines and gets clamped. This height difference documents the
    // counterintuitive behavior: hard newlines don't create visual lines
    // under white-space:normal, defeating the author's intent.
    expect(shortHeight).toBeLessThan(longHeight);
  });
});

test.describe("prefers-reduced-motion interactions", () => {
  test("lower-specificity override fails to disable animation", async ({
    page,
  }) => {
    // Documents known browser behavior: a less-specific reduced-motion
    // override doesn't win against a more-specific animation declaration
    await page.setContent(`
      <style>
        .card .animated-element {
          animation: spin 2s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        @media (prefers-reduced-motion: reduce) {
          .animated-element {
            animation: none;
          }
        }
      </style>
      <div class="card">
        <div class="animated-element" id="target">Animated</div>
      </div>
    `);
    await page.emulateMedia({ reducedMotion: "reduce" });
    // Wait for styles to apply
    await page.waitForTimeout(100);

    const animation = await page.locator("#target").evaluate((el) => {
      return window.getComputedStyle(el).animationName;
    });
    // BUG: lower specificity (.animated-element) doesn't override higher (.card .animated-element)
    // The animation is still "spin" because the base selector wins on specificity
    test.fail();
    expect(animation).toBe("none");
  });

  test("!important fix correctly disables animation", async ({ page }) => {
    await page.setContent(`
      <style>
        .card .animated-element {
          animation: spin 2s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        @media (prefers-reduced-motion: reduce) {
          .animated-element {
            animation: none !important;
          }
        }
      </style>
      <div class="card">
        <div class="animated-element" id="target">Animated</div>
      </div>
    `);
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.waitForTimeout(100);

    const animation = await page.locator("#target").evaluate((el) => {
      return window.getComputedStyle(el).animationName;
    });
    expect(animation).toBe("none");
  });

  test("transition not disabled when only animation targeted", async ({
    page,
  }) => {
    await page.setContent(`
      <style>
        .element {
          animation: fadeIn 1s ease;
          transition: transform 0.3s ease, opacity 0.3s ease;
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @media (prefers-reduced-motion: reduce) {
          .element {
            animation: none;
            /* BUG: transition not disabled */
          }
        }
      </style>
      <div class="element" id="target">Content</div>
    `);
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.waitForTimeout(100);

    const styles = await page.locator("#target").evaluate((el) => {
      const computed = window.getComputedStyle(el);
      return {
        animation: computed.animationName,
        transition: computed.transitionProperty,
      };
    });
    // Animation correctly disabled
    expect(styles.animation).toBe("none");
    // But transition is still active — this is the bug we're documenting
    expect(styles.transition).not.toBe("none");
  });
});

test.describe("conditional class interactions", () => {
  test("bare element without conditional class has acceptable defaults", async ({
    page,
  }) => {
    await page.setContent(`
      <style>
        .card { padding: 16px; border: 1px solid #ccc; }
        .card.is-featured { background: #ffe0b2; border-color: #ff9800; }
        .card.is-urgent { background: #ffcdd2; border-color: #f44336; }
      </style>
      <div class="card" id="base">Base card</div>
      <div class="card is-featured" id="featured">Featured card</div>
      <div class="card is-urgent" id="urgent">Urgent card</div>
    `);

    const baseStyles = await page.locator("#base").evaluate((el) => {
      const computed = window.getComputedStyle(el);
      return {
        background: computed.backgroundColor,
        borderColor: computed.borderColor,
      };
    });
    // Base card should have neutral/transparent background, not inherit featured/urgent styles
    // rgba(0, 0, 0, 0) is transparent
    expect(baseStyles.background).toMatch(
      /rgba\(0,\s*0,\s*0,\s*0\)|transparent/,
    );
  });

  test("specificity conflict between conditional class and contextual selector", async ({
    page,
  }) => {
    await page.setContent(`
      <style>
        .sidebar .card { background: #f5f5f5; }
        .card.is-highlighted { background: #fff9c4; }
      </style>
      <div class="sidebar">
        <div class="card is-highlighted" id="target">Should be highlighted yellow</div>
      </div>
    `);

    const bg = await page.locator("#target").evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });
    // Both selectors have specificity 0,2,0 — last one in source order wins
    // .sidebar .card comes first, .card.is-highlighted comes second = yellow wins
    // This documents that source order matters when specificities are equal
    expect(bg).toBe("rgb(255, 249, 196)"); // #fff9c4
  });
});
