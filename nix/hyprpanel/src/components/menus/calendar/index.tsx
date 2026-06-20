import DropdownMenu from '../shared/dropdown/index.js';
import { CalendarWidget } from './CalendarWidget.js';
import { WeatherWidget } from './weather/index';
import { bind } from 'astal';
import { RevealerTransitionMap } from 'src/components/settings/constants.js';
import options from 'src/configuration';
import { Gtk } from 'astal/gtk3';

const { transition } = options.menus;
const { enabled: weatherEnabled } = options.menus.clock.weather;

export default (): JSX.Element => {
    return (
        <DropdownMenu
            name={'calendarmenu'}
            transition={bind(transition).as((transition) => RevealerTransitionMap[transition])}
        >
            <box css={'padding: 1px; margin: -1px;'}>
                {bind(weatherEnabled).as((isWeatherEnabled) => {
                    return (
                        <box className={'menu-items calendar calendar-menu-content'} halign={Gtk.Align.FILL} hexpand>
                            <box className={'menu-items-container calendar calendar-content-container'} vertical>
                                <box className={'calendar-content-items'} vertical>
                                    <CalendarWidget />
                                    <WeatherWidget isEnabled={isWeatherEnabled} />
                                </box>
                            </box>
                        </box>
                    );
                })}
            </box>
        </DropdownMenu>
    );
};
