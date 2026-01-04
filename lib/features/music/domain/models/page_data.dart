/// Модель данных пагинации
///
/// Представляет страницу данных с информацией о текущей странице,
/// общем количестве элементов и наличии следующих/предыдущих страниц.
/// Используется для постраничной загрузки данных из API.
///
/// [T] - тип элементов на странице
class PageData<T> {
  final int pageNumber;
  final List<T> items;
  final bool hasNext;
  final bool hasPrevious;
  final int totalPages;
  final int totalItems;

  const PageData({
    required this.pageNumber,
    required this.items,
    required this.hasNext,
    required this.hasPrevious,
    required this.totalPages,
    required this.totalItems,
  });

  factory PageData.fromApiResponse(Map<String, dynamic> response, List<T> items) {
    return PageData(
      pageNumber: response['page'] ?? 1,
      items: items,
      hasNext: (response['page'] ?? 1) < (response['totalPages'] ?? 1),
      hasPrevious: (response['page'] ?? 1) > 1,
      totalPages: response['totalPages'] ?? 1,
      totalItems: response['totalItems'] ?? 0,
    );
  }
}
