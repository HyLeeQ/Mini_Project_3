import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/model/CategoryModel.dart';
import '../app_colors.dart';

class CategorySection extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCat;
  final ValueChanged<CategoryModel?> onSelected;

  const CategorySection({
    super.key,
    required this.categories,
    required this.selectedCat,
    required this.onSelected,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCats = categories.take(7).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Danh mục'),
          SizedBox(height: 10.h),
          categories.isEmpty
              ? _emptySection('Chưa có danh mục')
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.85,
                  children: [
                    ...visibleCats.map((cat) => _catCell(cat)),
                    _moreCatBtn(context, categories),
                  ],
                ),
          if (selectedCat != null &&
              !visibleCats.any((c) => c.id == selectedCat!.id)) ...[
            SizedBox(height: 10.h),
            _selectedExtraCat(),
          ],
        ],
      ),
    );
  }

  Widget _catCell(CategoryModel cat) {
    final isSelected = selectedCat?.id == cat.id;
    final color = _parseColor(cat.colorHex);
    return GestureDetector(
      onTap: () => onSelected(cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : AppColors.border,
            width: isSelected ? 1.5.w : 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Text(cat.icon, style: TextStyle(fontSize: 22.sp)),
            ),
            SizedBox(height: 5.h),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreCatBtn(BuildContext context, List<CategoryModel> allCats) {
    final visibleIds = allCats.take(7).map((c) => c.id).toSet();
    final hasExtraSelected =
        selectedCat != null && !visibleIds.contains(selectedCat!.id);

    return GestureDetector(
      onTap: () => _showBottomSheet(context, allCats),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: hasExtraSelected
              ? AppColors.gold.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasExtraSelected
                ? AppColors.gold.withOpacity(0.5)
                : AppColors.border,
            width: hasExtraSelected ? 1.5.w : 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '···',
              style: TextStyle(fontSize: 18.sp, color: AppColors.gold),
            ),
            SizedBox(height: 5.h),
            Text(
              'Khác',
              style: TextStyle(
                fontSize: 10.sp,
                color: hasExtraSelected
                    ? AppColors.gold
                    : AppColors.textSecondary,
                fontWeight: hasExtraSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedExtraCat() {
    final color = _parseColor(selectedCat!.colorHex);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.4), width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(selectedCat!.icon, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 8.w),
          Text(
            selectedCat!.name,
            style: TextStyle(
              fontSize: 13.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => onSelected(null),
            child: Icon(Icons.close_rounded, size: 15.sp, color: color),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, List<CategoryModel> allCats) {
    final searchCtrl = TextEditingController();
    List<CategoryModel> filtered = List.from(allCats);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void onSearch(String query) {
              setModalState(() {
                filtered = query.trim().isEmpty
                    ? List.from(allCats)
                    : allCats
                          .where(
                            (c) => c.name.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                border: Border.all(color: AppColors.border, width: 1.w),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Text(
                          'Chọn danh mục',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm hoặc nhập danh mục mới...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 18.sp,
                        ),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchCtrl.clear();
                                  onSearch('');
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textSecondary,
                                  size: 16.sp,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: AppColors.gold.withOpacity(0.5),
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (searchCtrl.text.trim().isNotEmpty && filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: GestureDetector(
                        onTap: () {
                          final newCat = CategoryModel(
                            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                            name: searchCtrl.text.trim(),
                            icon: '🏷️',
                            colorHex: '#7A7A8C',
                            type: CategoryType.expense,
                          );
                          onSelected(newCat);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.gold,
                                size: 18.sp,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Tạo mới: "${searchCtrl.text.trim()}"',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 4.h,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final cat = filtered[i];
                        final isSelected = selectedCat?.id == cat.id;
                        final color = _parseColor(cat.colorHex);
                        return GestureDetector(
                          onTap: () {
                            onSelected(cat);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSelected
                                    ? color.withOpacity(0.5)
                                    : AppColors.border,
                                width: isSelected ? 1.5.w : 1.w,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.icon,
                                  style: TextStyle(fontSize: 22.sp),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isSelected
                                        ? color
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );

  Widget _emptySection(String msg) => Container(
    height: 60.h,
    alignment: Alignment.center,
    child: Text(
      msg,
      style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
    ),
  );
}
