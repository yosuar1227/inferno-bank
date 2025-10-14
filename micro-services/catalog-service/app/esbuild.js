import * as esbuild from "esbuild"

esbuild
    .build({
        entryPoints: ["src/handlers/*.ts"],
        minify: true,
        bundle: true,
        outdir: "dist",
        outbase: "src",
        platform: "node",
        format: "cjs",
        tsconfig: "tsconfig.json",
        target: "node20.13.0",
        metafile: true,
    }).then((result) => {
        console.log("output file size for handler.js File");
        for (const [file, info] of Object.entries(result.metafile.outputs)) {
            const size = (info.bytes / 1024).toFixed(2);
            console.log(`${file}: ${size}KB`);
        }
    }).catch(err => {
        console.log(err);
        procces.exit(1);
    })