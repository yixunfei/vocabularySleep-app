import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_ai_interview_service.dart';

void main() {
  group('toolbox ai interview service', () {
    const service = ToolboxAiInterviewService();

    test('detects system design questions and builds architecture outline', () {
      final result = service.build(
        const ToolboxAiInterviewInput(
          question: '设计一个高并发短链接系统，需要考虑缓存、限流和数据库分片。',
          role: '后端工程师',
          resumeHighlights: '做过网关限流, Redis 缓存治理',
          depth: ToolboxAiInterviewDepth.deep,
        ),
      );

      expect(result.detectedType, ToolboxAiInterviewType.systemDesign);
      expect(
        result.answerOutline.map((item) => item.key),
        contains('life.ai_interview.outline.system_design.sla'),
      );
      expect(
        result.answerOutline.map((item) => item.key),
        contains('life.ai_interview.outline.system_design.cache_queue_storage'),
      );
      expect(result.followUpQuestions.length, greaterThan(3));
      expect(
        result.fallbackQuestionKey,
        'life.ai_interview.fallback_question.system_design',
      );
    });

    test('scores structured STAR draft higher than empty draft', () {
      final empty = service.build(
        const ToolboxAiInterviewInput(
          question: '讲一次你处理团队冲突的经历',
          resumeHighlights: '跨团队项目推进',
        ),
      );
      final structured = service.build(
        const ToolboxAiInterviewInput(
          question: '讲一次你处理团队冲突的经历',
          resumeHighlights: '跨团队项目推进',
          answerDraft:
              '背景是跨团队项目推进延迟，我负责协调接口和排期。Action 是拆出 3 个阻塞点并建立每日同步，结果两周内上线，缺陷率下降 20%，复盘后沉淀了协作模板。',
        ),
      );

      expect(empty.readinessScore, 0);
      expect(structured.readinessScore, greaterThan(empty.readinessScore));
      expect(
        structured.evaluationNotes.map((item) => item.key),
        contains('life.ai_interview.evaluation.ready_strong'),
      );
    });

    test(
      'keeps prompt local-practice oriented and includes safety boundaries',
      () {
        final result = service.build(
          const ToolboxAiInterviewInput(
            question: '',
            type: ToolboxAiInterviewType.hr,
            language: ToolboxAiInterviewLanguage.bilingual,
            tone: ToolboxAiInterviewTone.coaching,
          ),
        );

        expect(result.normalizedQuestion, isEmpty);
        expect(
          result.fallbackQuestionKey,
          'life.ai_interview.fallback_question.hr',
        );
        expect(
          result.boundaryNotes.map((item) => item.key),
          contains('life.ai_interview.boundary.local_practice'),
        );
      },
    );
  });
}
