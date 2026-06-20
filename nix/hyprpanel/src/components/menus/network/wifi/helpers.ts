import AstalNetwork from 'gi://AstalNetwork?version=0.1';
import { NetworkService } from 'src/services/network';

const networkService = NetworkService.getInstance();

/**
 * Determines whether an access point is password protected (shows a lock glyph,
 * matching macOS).
 *
 * @param accessPoint - The access point to inspect.
 * @returns True if the network is secured.
 */
export const isSecured = (accessPoint: AstalNetwork.AccessPoint): boolean => {
    return (accessPoint.rsnFlags ?? 0) !== 0 || (accessPoint.wpaFlags ?? 0) !== 0 || ((accessPoint.flags ?? 0) & 0x1) !== 0;
};

export interface CategorizedAPs {
    active?: AstalNetwork.AccessPoint;
    known: AstalNetwork.AccessPoint[];
    other: AstalNetwork.AccessPoint[];
}

/**
 * Splits the filtered access points into the macOS-style buckets: the connected
 * network, saved ("Known") networks, and everything else ("Other").
 *
 * @returns The categorized access points.
 */
export const categorizeAPs = (): CategorizedAPs => {
    const aps = networkService.wifi.getFilteredWirelessAPs();

    let active: AstalNetwork.AccessPoint | undefined;
    const known: AstalNetwork.AccessPoint[] = [];
    const other: AstalNetwork.AccessPoint[] = [];

    aps.forEach((ap) => {
        if (networkService.wifi.isApActive(ap)) {
            active = ap;
        } else if (networkService.wifi.isSavedNetwork(ap.ssid || '')) {
            known.push(ap);
        } else {
            other.push(ap);
        }
    });

    return { active, known, other };
};
