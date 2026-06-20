export type SystrayIconMap = {
    [key: string]: {
        icon?: string;
        color?: string;
        size?: string;
        file?: string;
        lightFile?: string;
        darkFile?: string;
        inputMethodLabels?: Record<string, string>;
        defaultInputMethodLabel?: string;
    };
};
