import type { NextConfig } from "next";

const nextConfig: NextConfig = {
    webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
        if (!isServer) {
          // We're in the browser build, so we can safely exclude the sharp module
          config.externals.push('sharp');
        }
        // shader support
        config.module.rules.push({
          test: /\.(glsl|vs|fs|vert|frag)$/,
          exclude: /node_modules/,
          use: ['raw-loader', 'glslify-loader'],
        });
        return config;
      },
};

export default nextConfig;
