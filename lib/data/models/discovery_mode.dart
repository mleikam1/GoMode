class DiscoveryMode {
  const DiscoveryMode({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const discoveryModes = <DiscoveryMode>[
  DiscoveryMode(
    id: 'date-night',
    title: 'Date night',
    description: 'Low-friction ideas for two.',
  ),
  DiscoveryMode(
    id: 'weekend',
    title: 'Weekend plans',
    description: 'Make the open day feel easy.',
  ),
  DiscoveryMode(
    id: 'food-wheel',
    title: 'Food wheel',
    description: 'Spin your way past indecision.',
  ),
  DiscoveryMode(
    id: 'road-trip',
    title: 'Road trip stops',
    description: 'Breaks, bites, and detours nearby.',
  ),
  DiscoveryMode(
    id: 'family',
    title: 'Family ideas',
    description: 'Kid-friendly moves without the hunt.',
  ),
  DiscoveryMode(
    id: 'pets',
    title: 'Pets',
    description: 'Parks, patios, and pet errands.',
  ),
  DiscoveryMode(
    id: 'health-outdoors',
    title: 'Health outdoors',
    description: 'Fresh-air options that fit today.',
  ),
  DiscoveryMode(
    id: 'home-life',
    title: 'Home life',
    description: 'Useful local stops and errands.',
  ),
  DiscoveryMode(
    id: 'local-games',
    title: 'Local games',
    description: 'Playful challenges around town.',
  ),
  DiscoveryMode(
    id: 'coffee',
    title: 'Coffee',
    description: 'Good places to reset or work.',
  ),
  DiscoveryMode(
    id: 'happy-hour',
    title: 'Happy hour',
    description: 'Casual drinks and small bites.',
  ),
  DiscoveryMode(
    id: 'live-music',
    title: 'Live music',
    description: 'Find a room with a pulse.',
  ),
  DiscoveryMode(
    id: 'arts-culture',
    title: 'Arts culture',
    description: 'Museums, exhibits, and shows.',
  ),
  DiscoveryMode(
    id: 'shopping',
    title: 'Shopping',
    description: 'Browse, gift, or get it done.',
  ),
  DiscoveryMode(
    id: 'rainy-day',
    title: 'Rainy day',
    description: 'Indoor plans that still feel alive.',
  ),
  DiscoveryMode(
    id: 'solo',
    title: 'Solo mode',
    description: 'Do something good on your own.',
  ),
  DiscoveryMode(
    id: 'friends',
    title: 'Friends',
    description: 'Group-friendly places and plans.',
  ),
  DiscoveryMode(
    id: 'budget',
    title: 'Budget',
    description: 'Low-cost ways to get moving.',
  ),
  DiscoveryMode(
    id: 'special-occasion',
    title: 'Special occasion',
    description: 'Make the moment feel considered.',
  ),
  DiscoveryMode(
    id: 'surprise-me',
    title: 'Surprise me',
    description: 'A wildcard when you just need a move.',
  ),
];
