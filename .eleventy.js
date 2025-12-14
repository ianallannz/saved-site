// .eleventy.js
import markdownIt from "markdown-it";
import markdownItAnchor from "markdown-it-anchor";
import { DateTime } from "luxon";
import slugify from "slugify";

export default function(eleventyConfig) {
  const md = markdownIt({ html: true, linkify: true })
    .use(markdownItAnchor, { permalink: true, permalinkClass: "direct-link", permalinkSymbol: "#" });

  // Markdown filter
  eleventyConfig.addNunjucksFilter("markdown", value => md.render(String(value || "")));
  eleventyConfig.setLibrary("md", md);

  // Slug filter
  eleventyConfig.addFilter("slug", input => slugify(input, { lower: true, strict: true }));

  // Date filter
  eleventyConfig.addFilter("date", (dateObj, format = "dd LLLL yyyy") =>
    DateTime.fromJSDate(dateObj).toFormat(format)
  );


  // Passthrough copies
  eleventyConfig.addPassthroughCopy({ "src/images": "images" });
  eleventyConfig.addPassthroughCopy({ "src/css": "css" });
  eleventyConfig.addPassthroughCopy({ "src/js": "js" });
  eleventyConfig.addPassthroughCopy({ "src/docs": "docs" });

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