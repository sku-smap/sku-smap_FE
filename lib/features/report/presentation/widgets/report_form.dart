import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/presentation/widgets/home_segmented.dart';
import '../../../home/presentation/widgets/pressable.dart';
import '../../../search/data/search_assets.dart';
import '../../data/report_models.dart';
import '../../data/report_options.dart';
import '../../state/report_controller.dart';
import '../report_tokens.dart';
import 'report_chip.dart';
import 'report_map.dart';
import 'report_photo_field.dart';

class ReportForm extends StatelessWidget {
  const ReportForm({
    super.key,
    required this.state,
    required this.controller,
    required this.fixedKind,
    required this.memo,
    required this.onAddPhoto,
    required this.onSend,
  });

  final ReportFormState state;
  final ReportController controller;
  final bool fixedKind;
  final TextEditingController memo;
  final VoidCallback onAddPhoto;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final kind = state.kind!;
    final canSend = state.ready && !state.sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          kind: kind,
          onBack: fixedKind ? null : () => controller.setKind(null),
        ),
        if (kind == ReportKind.closure) ...[
          const SizedBox(height: 6),
          Text('팀이 확인하면 다른 사람의 길안내가 이 지점을 피해서 가요.', style: ReportText.sheetSub),
        ],
        if (kind == ReportKind.course)
          _Field(
            label: '코스',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LocButton(
                  caption: '출발',
                  value: state.from?.label,
                  empty: '어디서 출발하나요?',
                  onTap: () => controller.startPick(ReportPick.from),
                ),
                const SizedBox(height: 6),
                _LocButton(
                  caption: '도착',
                  value: state.to?.label,
                  empty: '어디까지 가는 길인가요?',
                  onTap: () => controller.startPick(ReportPick.to),
                ),
              ],
            ),
          )
        else
          _Field(label: '위치', child: _locField(kind)),
        if (kind == ReportKind.issue || kind == ReportKind.closure)
          _Field(
            label: kind == ReportKind.closure ? '무슨 일인가요?' : '어떤 점이 달랐나요?',
            child: ReportChipWrap(
              options: kind == ReportKind.closure ? closureTypes : issueTypes,
              isOn: (t) => state.type == t,
              onTap: controller.toggleType,
            ),
          ),
        if (kind == ReportKind.closure)
          _Field(
            label: '언제까지일 것 같나요?',
            child: Align(
              alignment: Alignment.centerLeft,
              child: HomeSegmented<int?>(
                options: closureDurations,
                selected: state.days,
                onChanged: controller.setDays,
              ),
            ),
          ),
        if (kind == ReportKind.course)
          _Field(
            label: '어떤 사람에게 좋은 길인가요? (여러 개)',
            child: ReportChipWrap(
              options: courseTags,
              isOn: state.tags.contains,
              onTap: controller.toggleTag,
            ),
          ),
        if (kind != ReportKind.praise)
          _Field(
            label: '사진 (선택)',
            child: ReportPhotoField(
              photo: state.photo,
              onAdd: onAddPhoto,
              onRemove: () => controller.setPhoto(null),
            ),
          ),
        const SizedBox(height: 14),
        _Memo(
          controller: memo,
          hint: kind.memoHint,
          onChanged: controller.setMemo,
        ),
        const SizedBox(height: ReportLayout.fieldGap),
        Pressable(
          onTap: canSend ? onSend : null,
          builder: (context, pressed) => Container(
            height: ReportLayout.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: !canSend
                  ? ReportColors.disabled
                  : pressed
                  ? ReportColors.pressed
                  : ReportColors.blue,
              borderRadius: BorderRadius.circular(ReportLayout.buttonRadius),
            ),
            child: Text(
              state.sending ? '보내는 중…' : '보내기',
              style: ReportText.button,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locField(ReportKind kind) {
    final loc = state.loc;
    final empty = kind == ReportKind.issue ? '위치 없음 (내용에 적어주세요)' : '위치를 골라주세요';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loc?.label ?? empty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: loc == null ? ReportText.locEmpty : ReportText.locValue,
              ),
            ),
            const SizedBox(width: ReportLayout.chipGap),
            ReportChip(
              label: '검색',
              tone: ChipTone.ghost,
              onTap: () => controller.startPick(ReportPick.loc),
            ),
            const SizedBox(width: ReportLayout.chipGap),
            ReportChip(
              label: '지도에서',
              tone: state.mapOpen ? ChipTone.primary : ChipTone.ghost,
              selected: state.mapOpen,
              onTap: controller.toggleMap,
            ),
          ],
        ),
        if (state.mapOpen) ...[
          const SizedBox(height: 10),
          ReportMap(
            level: state.level,
            current: loc?.node,
            onLevel: controller.setLevel,
            onPick: controller.mapPicked,
          ),
          const SizedBox(height: 6),
          Text('지도를 누르면 가장 가까운 촬영 지점이 골라져요', style: ReportText.hint),
        ],
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.kind, required this.onBack});

  final ReportKind kind;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    final title = Text(
      '${kind.icon} ${kind.title}',
      style: ReportText.sheetTitle,
    );
    if (back == null) return title;
    // The back button sits half a gutter left of the sheet edge
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Row(
        children: [
          Pressable(
            onTap: back,
            label: '종류 다시 고르기',
            builder: (context, pressed) => SizedBox.square(
              dimension: ReportLayout.iconButton,
              child: Center(
                child: SvgPicture.asset(
                  SearchAssets.back,
                  width: ReportLayout.backIcon,
                  height: ReportLayout.backIcon,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: title),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ReportLayout.fieldGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: ReportText.label),
          const SizedBox(height: ReportLayout.labelGap),
          child,
        ],
      ),
    );
  }
}

class _LocButton extends StatelessWidget {
  const _LocButton({
    required this.caption,
    required this.value,
    required this.empty,
    required this.onTap,
  });

  final String caption;
  final String? value;
  final String empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) => Container(
        height: ReportLayout.locHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: pressed ? ReportColors.line : ReportColors.field,
          borderRadius: BorderRadius.circular(ReportLayout.fieldRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caption, style: ReportText.locSmall),
            Text(
              value ?? empty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: value == null ? ReportText.locEmpty : ReportText.locValue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Memo extends StatelessWidget {
  const _Memo({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ReportLayout.memoHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportColors.surface,
        border: Border.all(color: ReportColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(ReportLayout.fieldRadius),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        expands: true,
        maxLines: null,
        style: ReportText.memo,
        cursorColor: ReportColors.blue,
        textAlignVertical: TextAlignVertical.top,
        inputFormatters: [LengthLimitingTextInputFormatter(reportMemoMax)],
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: ReportText.memoHint,
        ),
      ),
    );
  }
}
