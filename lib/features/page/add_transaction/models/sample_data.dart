import '../../../../data/firebase/WalletStorage.dart';
import '../../../../data/model/CategoryModel.dart';
import '../../../../data/model/WalletModel.dart';
class SampleData {
  final walletStorage = WalletStorage();
  SampleData._();

  static const List<CategoryModel> categories = [
    CategoryModel(id: '1',  name: 'Ăn uống',   icon: '🍔', colorHex: '#E05555', type: CategoryType.expense),
    CategoryModel(id: '2',  name: 'Shopping',   icon: '🛍️', colorHex: '#D4A843', type: CategoryType.expense),
    CategoryModel(id: '3',  name: 'Di chuyển',  icon: '🚗', colorHex: '#5B8CFF', type: CategoryType.expense),
    CategoryModel(id: '4',  name: 'Sức khỏe',   icon: '💊', colorHex: '#2ECC8A', type: CategoryType.expense),
    CategoryModel(id: '5',  name: 'Giải trí',   icon: '🎬', colorHex: '#B05BFF', type: CategoryType.expense),
    CategoryModel(id: '6',  name: 'Nhà ở',      icon: '🏠', colorHex: '#FF8C42', type: CategoryType.expense),
    CategoryModel(id: '9',  name: 'Hóa đơn',    icon: '📄', colorHex: '#FF8C42', type: CategoryType.expense),
    CategoryModel(id: '10', name: 'Giáo dục',   icon: '📚', colorHex: '#5B8CFF', type: CategoryType.expense),
    CategoryModel(id: '11', name: 'Du lịch',    icon: '✈️', colorHex: '#B05BFF', type: CategoryType.expense),
    CategoryModel(id: '12', name: 'Trả nợ',     icon: '💸', colorHex: '#E05555', type: CategoryType.expense),
    CategoryModel(id: '13', name: 'Đầu tư',     icon: '📈', colorHex: '#2ECC8A', type: CategoryType.expense),
    CategoryModel(id: '14', name: 'Bảo hiểm',   icon: '🛡️', colorHex: '#D4A843', type: CategoryType.expense),
    CategoryModel(id: '15', name: 'Thú cưng',   icon: '🐾', colorHex: '#FF8C42', type: CategoryType.expense),
    CategoryModel(id: '16', name: 'Quà tặng',   icon: '🎀', colorHex: '#B05BFF', type: CategoryType.expense),
    CategoryModel(id: '17', name: 'Từ thiện',   icon: '❤️', colorHex: '#E05555', type: CategoryType.expense),
    CategoryModel(id: '18', name: 'Làm đẹp',    icon: '💄', colorHex: '#D4A843', type: CategoryType.expense),
    CategoryModel(id: '19', name: 'Thể thao',   icon: '⚽', colorHex: '#2ECC8A', type: CategoryType.expense),
    CategoryModel(id: '20', name: 'Điện tử',    icon: '📱', colorHex: '#5B8CFF', type: CategoryType.expense),
    CategoryModel(id: '7',  name: 'Lương',      icon: '💰', colorHex: '#2ECC8A', type: CategoryType.income),
    CategoryModel(id: '8',  name: 'Thưởng',     icon: '🎁', colorHex: '#D4A843', type: CategoryType.income),
  ];

}