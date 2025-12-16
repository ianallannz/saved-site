// .eleventy.js
import fs from "fs";
import markdownIt from "markdown-it";
import markdownItAnchor from "markdown-it-anchor";
import { DateTime } from "luxon";
import slugify from "slugify";


export default function(eleventyConfig) {
  // define a shared slugify function
  const slugFn = s => slugify(s, { lower: true, strict: true });

  const md = markdownIt({ html: true, linkify: true })
    .use(markdownItAnchor, {
      permalink: true,
      permalinkClass: "direct-link",
      permalinkSymbol: "#",
      slugify: slugFn
    });

  eleventyConfig.addShortcode("mdheadings", (path) => {
    const text = fs.readFileSync(`src/${path}`, "utf-8");
    const headings = [];
    const regex = /^(#{2,4})\s+(.*)$/gm;
    let match;
    while ((match = regex.exec(text)) !== null) {
      const level = match[1].length;
      const title = match[2];
      const slug = slugFn(title); // use the same function here
      headings.push({ level, title, slug });
    }
    return headings
      .map(h => `<li class="h${h.level}"><a href="#${h.slug}">${h.title}</a></li>`)
      .join("\n");
  });

  eleventyConfig.addPairedShortcode("markdown", content => md.render(content));
  eleventyConfig.addNunjucksFilter("markdown", value => md.render(String(value || "")));
  eleventyConfig.setLibrary("md", md);

  eleventyConfig.addShortcode("mdfile", (path) => {
    const text = fs.readFileSync(`src/${path}`, "utf-8");
    return md.render(text);
  });

  eleventyConfig.addFilter("slug", input => slugFn(input));

  eleventyConfig.addFilter("date", (dateObj, format = "dd LLLL yyyy") =>
    DateTime.fromJSDate(dateObj).toFormat(format)
  );

  eleventyConfig.addPassthroughCopy({ "src/images": "images" });
  eleventyConfig.addPassthroughCopy({ "src/css": "css" });
  eleventyConfig.addPassthroughCopy({ "src/js": "js" });
  eleventyConfig.addPassthroughCopy({ "src/docs": "docs" });

  eleventyConfig.addPassthroughCopy({
  "node_modules/@fontsource/commit-mono": "css/commit-mono"
});


  return {
    dir: {
      input: "src",
      output: "_site",
      includes: "_includes",
      layouts: "_includes/layouts"
    },
    templateFormats: ["md", "njk", "html"],
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
    dataTemplateEngine: "njk"
  };
}
