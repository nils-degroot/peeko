import path from "node:path";
import { PurgeCSS } from "purgecss";
import purgeCssFromHtml from "purgecss-from-html";
import EleventyPluginPug from "@11ty/eleventy-plugin-pug";
import CleanCSS from "clean-css";
import { compileString } from "sass";
import HtmlMinifier from "html-minifier";

export default function (eleventyConfig) {
	eleventyConfig.setInputDirectory("src");

	eleventyConfig.addTemplateFormats("scss");

	eleventyConfig.addPlugin(EleventyPluginPug);

	eleventyConfig.addExtension("scss", {
		outputFileExtension: "css",
		useLayouts: false,

		compile: async function (inputContent, inputPath) {
			let parsed = path.parse(inputPath);

			if (parsed.name.startsWith("_")) {
				return;
			}

			let result = compileString(inputContent, {
				loadPaths: [parsed.dir || ".", this.config.dir.includes],
			});

			this.addDependencies(inputPath, result.loadedUrls);

			return async () => result.css;
		},
	});

	eleventyConfig.addTransform(
		"purge-and-inline-css",
		async (content, outputPath) => {
			if (outputPath && outputPath.endsWith(".html")) {
				const purgeCssResult = await new PurgeCSS().purge({
					content: [{ raw: content, extension: "html" }],
					css: ["_site/main.css"],
					extractors: [
						{
							extractor: purgeCssFromHtml,
							extensions: ["html"],
						},
					],
				});

				const minifyResult = new CleanCSS().minify(purgeCssResult[0].css);

				return content.replace(
					"<!-- INLINE CSS -->",
					`<style>${minifyResult.styles}</style>`,
				);
			}

			return content;
		},
	);

	eleventyConfig.addTransform("minify-html", async (content, outputPath) => {
		return outputPath && outputPath.endsWith(".html")
			? HtmlMinifier.minify(content)
			: content;
	});

	eleventyConfig.addPassthroughCopy("src/**/*.js");
}
