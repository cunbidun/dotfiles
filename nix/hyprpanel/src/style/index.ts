import { initializeTrackers } from './optionsTrackers';
import { readFile, writeFile } from 'astal/file';
import { App } from 'astal/gtk3';
import { GLib } from 'astal/gobject';
import { initializeHotReload } from './utils/hotReload';
import { Opt } from 'src/lib/options';
import { SystemUtilities } from 'src/core/system/SystemUtilities';
import options from 'src/configuration';

const stylixStateDir = `${GLib.get_home_dir()}/.local/state/stylix`;
const stylixThemeNamePath = `${stylixStateDir}/current-theme-name.txt`;
const stylixThemeConfigPath = `${stylixStateDir}/theme-config.json`;

const fallbackThemeMap: Record<string, string> = {
    'catppuccin-light': 'catppuccin_mocha',
    'catppuccin-dark': 'catppuccin_mocha',
    'default-light': 'monochrome',
    'default-dark': 'monochrome',
};

type ThemeVariantConfig = {
    hyprpanelTheme?: string;
};

type ThemeConfigMap = Record<string, Record<string, ThemeVariantConfig>>;

/**
 * Central manager for theme styling throughout the application
 * Handles the transformation of theme options into compiled CSS
 */
class ThemeStyleManager {
    /**
     * Orchestrates the full theme regeneration process
     */
    public async applyCss(): Promise<void> {
        if (!SystemUtilities.checkDependencies('sass')) return;

        try {
            const variables = await this._generateThemeVariables();

            await this._compileSass(variables);

            this._applyCss();
        } catch (error) {
            console.error(error);
        }
    }

    /**
     * Builds SCSS variables using options, with theme overrides selected from Stylix theme state.
     */
    private async _generateThemeVariables(): Promise<string[]> {
        const themeOverrides = this._readThemeOverridesForCurrentStylixTheme();
        return this._extractStandardVariables(themeOverrides);
    }

    private _readThemeOverridesForCurrentStylixTheme(): Record<string, unknown> {
        const currentThemeName = this._readTextFile(stylixThemeNamePath);
        if (!currentThemeName) {
            return {};
        }

        const hyprpanelThemeName =
            this._resolveHyprpanelThemeFromConfig(currentThemeName) ?? fallbackThemeMap[currentThemeName];
        if (!hyprpanelThemeName) {
            return {};
        }

        const themeJsonPath = `${SRC_DIR}/themes/${hyprpanelThemeName}.json`;

        if (!GLib.file_test(themeJsonPath, GLib.FileTest.EXISTS)) {
            console.warn(`[Theme] Theme file not found: ${themeJsonPath}`);
            return {};
        }

        const parsedTheme = this._readJsonFile(themeJsonPath);
        if (!parsedTheme) {
            return {};
        }

        return parsedTheme;
    }

    private _resolveHyprpanelThemeFromConfig(currentThemeName: string): string | undefined {
        const match = currentThemeName.match(/^(.*)-(light|dark)$/);
        if (!match) {
            return;
        }

        const [, themeName, polarity] = match;
        const themeConfig = this._readJsonFile(stylixThemeConfigPath) as ThemeConfigMap | null;
        if (!themeConfig) {
            return;
        }

        const mappedTheme = themeConfig[themeName]?.[polarity]?.hyprpanelTheme;
        return typeof mappedTheme === 'string' ? mappedTheme : undefined;
    }

    private _readJsonFile(path: string): Record<string, unknown> | null {
        if (!GLib.file_test(path, GLib.FileTest.EXISTS)) {
            return null;
        }

        try {
            const fileContent = readFile(path).trim();
            if (fileContent.length === 0) {
                return null;
            }

            const parsed = JSON.parse(fileContent);
            if (typeof parsed === 'object' && parsed !== null) {
                return parsed as Record<string, unknown>;
            }

            return null;
        } catch (error) {
            console.warn(`[Theme] Failed to parse JSON file ${path}:`, error);
            return null;
        }
    }

    private _readTextFile(path: string): string | null {
        if (!GLib.file_test(path, GLib.FileTest.EXISTS)) {
            return null;
        }

        const content = readFile(path).trim();
        return content.length > 0 ? content : null;
    }

    /**
     * Recursively processes theme objects to generate SCSS variables
     * Handles nested properties by creating properly namespaced variable names
     *
     * @returns An array of SCSS variable declarations using standard theme values
     */
    private _extractStandardVariables(themeOverrides: Record<string, unknown>): string[] {
        const cssVariables: string[] = [];

        const optArray = options.toArray();

        for (const opt of optArray) {
            const currentPath = opt.id;

            if (!currentPath.startsWith('theme.')) {
                continue;
            }

            const variableName = this._buildCssVariableName(currentPath);
            const variable = this._buildCssVariable(variableName, opt, themeOverrides[currentPath]);

            cssVariables.push(variable);
        }

        return cssVariables;
    }

    /**
     * Handles object properties that have values needing transformation
     * Creates properly formatted SCSS variable declarations
     *
     * @param variableName - CSS-friendly variable name
     * @param property - Option object containing the property value
     * @returns Formatted SCSS variable declaration
     */
    private _buildCssVariable(variableName: string, property: Opt, override?: unknown): string {
        const overrideType = typeof override;
        const hasPrimitiveOverride =
            overrideType === 'string' || overrideType === 'number' || overrideType === 'boolean';
        const propertyValue = hasPrimitiveOverride ? override : property.get();

        return `$${variableName}: ${propertyValue};`;
    }

    /**
     * Transforms dotted paths into hyphenated CSS variable names
     * Strips the "theme." prefix for cleaner variable naming
     *
     * @param path - Dot-notation path of an option (e.g., "theme.background.primary")
     * @returns CSS-friendly variable name (e.g., "background-primary")
     */
    private _buildCssVariableName(path: string): string {
        return path.replace('theme.', '').split('.').join('-');
    }

    /**
     * Executes the SCSS compilation process with generated variables
     * Combines main SCSS with custom variables and module styles
     *
     * @param themeVariables - Array of SCSS variable declarations for user customization options
     *
     * File paths used in compilation:
     * - themeVariablesPath: Contains all user-configurable variables (theme colors, margins, borders, etc.)
     * - appScssPath: The application's main SCSS entry point file
     * - entryScssPath: A temporary file that combines all SCSS sources in the correct order
     * - modulesScssPath: User-defined custom module styles
     * - compiledCssPath: The final compiled CSS that gets used by the application
     */
    private async _compileSass(themeVariables: string[]): Promise<void> {
        const themeVariablesPath = `${TMP}/variables.scss`;
        const appScssPath = `${SRC_DIR}/src/style/main.scss`;
        const entryScssPath = `${TMP}/entry.scss`;
        const modulesScssPath = `${CONFIG_DIR}/modules.scss`;
        const compiledCssPath = `${TMP}/main.css`;

        const scssImports = [`@import '${themeVariablesPath}';`];

        writeFile(themeVariablesPath, themeVariables.join('\n'));

        let combinedScss = readFile(appScssPath);
        combinedScss = `${scssImports.join('\n')}\n${combinedScss}`;

        const moduleCustomizations = readFile(modulesScssPath);
        combinedScss = `${combinedScss}\n${moduleCustomizations}`;

        writeFile(entryScssPath, combinedScss);

        await SystemUtilities.bash(
            `sass --load-path=${SRC_DIR}/src/style ${entryScssPath} ${compiledCssPath}`,
        );
    }

    /**
     * Loads the compiled CSS into the application
     *
     * @remarks
     * Uses the compiled CSS file generated in _compileSass to apply styles to the application
     */
    private _applyCss(): void {
        const compiledCssPath = `${TMP}/main.css`;

        App.apply_css(compiledCssPath, true);
    }
}

const themeManager = new ThemeStyleManager();
const optionsToWatch = [
    'font',
    'theme',
    'bar.flatButtons',
    'bar.position',
    'bar.battery.charging',
    'bar.battery.blocks',
];

initializeTrackers(themeManager.applyCss.bind(themeManager));
initializeHotReload();

options.handler(optionsToWatch, themeManager.applyCss.bind(themeManager));

await themeManager.applyCss();

export { themeManager };
