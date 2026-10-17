class Page<T> {
  const Page(
      {required this.items,
      required this.total,
      required this.limit,
      required this.offset});
  final List<T> items;
  final int total, limit, offset;
}
