import 'dart:io';

/// The address the board tells phones to use.
///
/// No Android Wi-Fi API is involved: `NetworkInterface.list` is the SDK, needs
/// no permission, and answers the only question that matters — "which of my
/// addresses can another device on this network reach?".
///
/// Returns null when the device is on no network at all, which the board turns
/// into a plain refusal rather than a room nobody can join.
Future<String?> findLocalIpv4() async {
  final List<NetworkInterface> interfaces;
  try {
    interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
  } on Object {
    return null;
  }

  // Wi-Fi first: on Android that is `wlan0`, and it is the interface a phone at
  // the table can actually reach. A hotspot may present as `ap0` or `swlan0`.
  for (final interface in interfaces) {
    if (_isWifiLike(interface.name)) {
      final address = _firstUsable(interface);
      if (address != null) return address;
    }
  }

  // Anything else that is not the loopback: USB tethering, Ethernet, a
  // desktop machine running the probe.
  for (final interface in interfaces) {
    if (interface.name.startsWith('lo')) continue;
    final address = _firstUsable(interface);
    if (address != null) return address;
  }

  return null;
}

bool _isWifiLike(String name) {
  final lower = name.toLowerCase();
  return lower.contains('wlan') ||
      lower.startsWith('ap') ||
      lower.contains('swlan');
}

String? _firstUsable(NetworkInterface interface) {
  for (final address in interface.addresses) {
    if (address.isLoopback) continue;
    if (address.type != InternetAddressType.IPv4) continue;
    return address.address;
  }
  return null;
}
