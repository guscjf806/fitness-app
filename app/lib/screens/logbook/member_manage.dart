import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mock_data.dart';
import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'log_write.dart';

/// 회원 한 줄: 마지막 일지 날짜와 일지 작성 버튼. 회원 관리와 선생님 홈이 같이 쓴다
class MemberLogRow extends StatelessWidget {
  const MemberLogRow(this.member, {super.key});
  final String member;

  @override
  Widget build(BuildContext context) => LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member, style: AppText.bodyStrong),
          Muted(demo.lastLogOf(member) == null ? '아직 쓴 일지가 없어요' : '마지막 일지 ${demo.lastLogOf(member)}', bottom: 0),
          if (hasLogDraft(member)) const Muted('임시 저장한 일지가 있어요', bottom: 0),
        ]),
        right: Row(mainAxisSize: MainAxisSize.min, children: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pushNamed(context, Routes.logWrite, arguments: member),
            child: Text(hasLogDraft(member) ? '이어 쓰기' : '일지 작성'),
          ),
          IconButton(
            tooltip: '$member 회원 더 보기',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showMemberSheet(context, member),
          ),
        ]),
      );
}

/// 회원 더 보기: 보낸 일지와 연결 끊기
void showMemberSheet(BuildContext context, String member) {
  showAppSheet<void>(
    context,
    builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      SheetTitle('$member 회원'),
      // 보낸 일지를 다시 보고 고치거나 지운다 (결정 d1104-3)
      const H2('보낸 일지'),
      if ((demo.sentLogs[member] ?? const []).isEmpty) const Muted('앱에서 보낸 일지가 아직 없어요.'),
      for (final log in demo.sentLogs[member] ?? const <WorkoutLog>[])
        LineRow(
          left: WordText('${log.date} · ${log.title}${log.edited ? ' · 수정됨' : ''}'),
          right: Row(mainAxisSize: MainAxisSize.min, children: [
            TextButton(
              onPressed: () {
                Navigator.pop(sheet);
                Navigator.pushNamed(context, Routes.logWrite, arguments: LogEditArgs(member, log));
              },
              child: const Text('고치기'),
            ),
            DangerTextButton(
              '지우기',
              onPressed: () async {
                final ok = await confirmDialog(sheet,
                    title: '${log.date} 일지를 지울까요?',
                    body: '회원님 화면에서도 사라지고 되돌릴 수 없어요.',
                    keepLabel: '그대로 두기',
                    okLabel: '지우기',
                    danger: true);
                if (!ok || !sheet.mounted) return;
                demo.update(() {
                  demo.sentLogs[member]?.remove(log);
                  demo.unseenLogs.remove(log);
                });
                Navigator.pop(sheet);
                if (context.mounted) toast(context, '일지를 지웠어요');
              },
            ),
          ]),
        ),
      const SizedBox(height: AppSpace.m),
      LineRow(
        left: const Text('연결 끊기', style: TextStyle(color: AppColors.warningText)),
        onTap: () async {
          // 회원과 선생님 모두 끊을 수 있고 상대에게 알린다 (결정 d1104-2)
          final ok = await confirmDialog(sheet,
              title: '$member 회원과 연결을 끊을까요?',
              body: '더 이상 이 회원의 일지를 볼 수 없어요. 회원님께 알림이 가요. 보낸 미션과 임시 저장한 일지도 함께 지워져요.',
              keepLabel: '그대로 두기',
              okLabel: '연결 끊기',
              danger: true);
          if (!ok || !sheet.mounted) return;
          demo.update(() {
            demo.removedMembers.add(member);
            demo.missions.remove(member);
            // 다시 이어졌을 때 옛 임시 저장이 뜨지 않게 (리뷰 11/08 #4)
            clearLogDraft(member);
          });
          Navigator.pop(sheet);
          if (context.mounted) toast(context, '$member 회원과 연결을 끊고 알렸어요');
        },
      ),
    ]),
  );
}

/// S18 회원 관리 (선생님)
class MemberManageTab extends StatefulWidget {
  const MemberManageTab({super.key});

  @override
  State<MemberManageTab> createState() => _MemberManageTabState();
}

class _MemberManageTabState extends State<MemberManageTab> {
  /// 미션 받을 회원. 연결을 끊은 회원은 고를 수 없다
  String? get member {
    final active = demo.activeMembers;
    if (active.contains(demo.missionMember)) return demo.missionMember;
    return active.isEmpty ? null : active.first;
  }
  final missionController = TextEditingController();
  final inviteMemoController = TextEditingController();

  @override
  void dispose() {
    missionController.dispose();
    inviteMemoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = this.member;
    return TabBody(children: [
      const H1('회원 관리'),
      // 수업 끝나고 가장 자주 쓰는 회원 목록을 맨 위로, 가끔 쓰는 초대 코드는 맨 아래로 (리뷰 11/04 #3)
      if (demo.activeMembers.isEmpty) const Muted('연결된 회원이 없어요. 아래에서 초대 코드를 만들어 보세요.'),
      for (final m in demo.activeMembers) MemberLogRow(m),
      const SizedBox(height: AppSpace.l),
      if (member != null) AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 주 미션', bottom: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(member),
            initialValue: member,
            items: [for (final m in demo.activeMembers) DropdownMenuItem(value: m, child: Text(m))],
            onChanged: (v) => setState(() => demo.missionMember = v),
          ),
          // 고른 회원에게 지금 보낸 미션을 보여 준다 (리뷰 11/02 #4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Muted(demo.missions[member] == null ? '아직 보낸 미션이 없어요' : '지금 미션: ${demo.missions[member]}', bottom: 0),
          ),
          const SizedBox(height: AppSpace.s),
          TextField(
            controller: missionController,
            decoration: const InputDecoration(hintText: '예: 이번 주 운동 3회 + 단백질 챙기기'),
          ),
          // 다른 회원에게 보내지 않게 버튼에 이름을 쓰고, 있던 미션은 말없이 덮어쓰지 않는다 (리뷰 11/04 #2)
          AppButton(demo.missions[member] == null ? '$member 회원님께 보내기' : '$member 회원님 미션 바꾸기', kind: ButtonKind.soft,
              onPressed: () async {
            final text = missionController.text.trim();
            // 빈칸이면 회색 예시 문구가 그대로 보내지지 않게 막는다
            if (text.isEmpty) {
              toast(context, '미션 내용을 적어 주세요');
              return;
            }
            final old = demo.missions[member];
            if (old != null) {
              final ok = await confirmDialog(context,
                  title: '$member 회원님 미션을 바꿀까요?',
                  body: '지금 미션: $old',
                  keepLabel: '그대로 두기',
                  okLabel: '바꾸기');
              if (!ok || !context.mounted) return;
            }
            demo.update(() => demo.missions[member] = text);
            missionController.clear();
            toast(context, '$member 회원님께 이번 주 미션을 보냈어요');
          }),
        ]),
      ),
      const SizedBox(height: AppSpace.s),
      // 회원 이름(또는 메모)을 먼저 적고 만든다. 어느 코드가 누구 것인지 헷갈리지 않게 (결정 d1102-3)
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('새 회원 초대', sub: '회원 이름이나 메모를 먼저 적어 주세요'),
          const SizedBox(height: AppSpace.s),
          TextField(
            controller: inviteMemoController,
            decoration: const InputDecoration(hintText: '예: 김지아 회원님'),
          ),
          AppButton('초대 코드 만들기', kind: ButtonKind.soft, onPressed: () {
            final memo = inviteMemoController.text.trim();
            if (memo.isEmpty) {
              toast(context, '회원 이름이나 메모를 적어 주세요');
              return;
            }
            demo.update(() => demo.inviteCodes.insert(0, InviteCode(memo, '${100000 + Random().nextInt(900000)}')));
            inviteMemoController.clear();
            // 만들어졌는지 몰라 또 누르지 않게 알린다 (리뷰 11/08 #3)
            toast(context, "'$memo' 초대 코드를 만들었어요. 바로 아래에 있어요");
          }),
        ]),
      ),
      for (final c in demo.inviteCodes)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.memo, style: AppText.bodyStrong)),
              // 잘못 만들었거나 안 쓴 코드를 지운다 (리뷰 11/08 #3)
              DangerTextButton('지우기', onPressed: () async {
                final ok = await confirmDialog(context,
                    title: '${c.memo} 초대 코드를 지울까요?',
                    body: '지우면 이 코드로는 연결할 수 없어요.',
                    keepLabel: '그대로 두기',
                    okLabel: '지우기',
                    danger: true);
                if (!ok) return;
                demo.update(() => demo.inviteCodes.remove(c));
                if (context.mounted) toast(context, '초대 코드를 지웠어요');
              }),
            ]),
            Muted('1회용 · ${c.daysLeft}일 남음', bottom: 2),
            Row(children: [
              Expanded(child: BigNumber(c.code)),
              // 손으로 옮겨 적지 않게 복사 버튼
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: c.code));
                  if (context.mounted) toast(context, '초대 코드를 복사했어요');
                },
              ),
            ]),
          ]),
        ),
    ]);
  }
}
