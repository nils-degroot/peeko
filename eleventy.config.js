import pugPlugin from "@11ty/eleventy-plugin-pug";
import CleanCSS from "clean-css";
import path from "node:path";
import * as sass from "sass";

export default function (eleventyConfig) {
	eleventyConfig.setInputDirectory("src");

	eleventyConfig.addPlugin(pugPlugin, {
		filters: {
			scssmin: function (text, options) {
				let result = sass.compileString(text, {
					loadPaths: ["."],
				});

				return new CleanCSS({}).minify(result.css).styles;
			},
		},
	});

	eleventyConfig.addTemplateFormats("scss");

	eleventyConfig.addExtension("scss", {
		outputFileExtension: "css",
		useLayouts: false,

		compile: async function (inputContent, inputPath) {
			let parsed = path.parse(inputPath);

			if (parsed.name.startsWith("_")) {
				return;
			}

			let result = sass.compileString(inputContent, {
				loadPaths: [parsed.dir || ".", this.config.dir.includes],
			});

			this.addDependencies(inputPath, result.loadedUrls);

			return async () => result.css;
		},
	});

	eleventyConfig.addPassthroughCopy("src/**/*.js");
}
