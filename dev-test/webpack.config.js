const path = require('path')
const HtmlWebpackPlugin = require("html-webpack-plugin")
const {ModuleFederationPlugin} = require("webpack").container
const TsconfigPathsPlugin = require("tsconfig-paths-webpack-plugin")

module.exports = {
    mode: "development",
    entry: {
        app: path.join(__dirname, "src", "index.tsx")
    },
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
    },
    devServer: {
        static: {
            directory: path.join(__dirname, 'dist'),
        },
        compress: true,
        port: 9000,
    },
    module: {
        rules: [
            {
                test: /\.jsx?$/,
                loader: "babel-loader",
                exclude: /node_modules/,
                options: {
                    presets: ["@babel/preset-react"]
                },
            },
            {
                test: /\.(tsx|ts)?$/,
                include: path.resolve(__dirname, "src"),
                use: [
                    {
                        loader: "ts-loader",
                        options: {
                            transpileOnly: true,
                            experimentalWatchApi: true,
                        }
                    }
                ]
            }
        ],
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: "./src/index.html"
        }),
        new ModuleFederationPlugin({
            name: "apicurioRegistry",
            remotes: {
                registry: "apicurio_registry@http://localhost:8888/apicurio_registry.js"
            },
            shared: {
                react: {
                    singleton: true
                },
                "react-dom": {
                    singleton: true
                },
                "react-router-dom": {
                    singleton: true
                }
            }
        })
    ],
    resolve: {
        extensions: [".ts", ".tsx", ".js"],
        plugins: [
            new TsconfigPathsPlugin({
                configFile: path.resolve(__dirname, "./tsconfig.json")
            })
        ],
        symlinks: false,
        cacheWithContext: false
    },
    performance: {
        hints: false,
        maxEntrypointSize: 2097152,
        maxAssetSize: 1048576
    }
}
