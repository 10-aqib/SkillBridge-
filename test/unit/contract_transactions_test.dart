import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_transactions.dart';

/// Never reached: these tests cover checks made before anything is sent.
class _NoDb extends Fake implements FirebaseFirestore {}

Matcher _refused(ContractStepProblem p) =>
    throwsA(isA<ContractStepException>().having((e) => e.problem, 'problem', p));

void main() {
  group('stage of a contract (same as the rules and the old function)', () {
    test('pending is a booking request', () {
      expect(contractStageOf({'status': 'pending'}), 'requested');
    });
    test('active: not started → in progress → submitted', () {
      expect(contractStageOf({'status': 'active'}), 'not_started');
      expect(contractStageOf({'status': 'active', 'workStartedAt': Timestamp.now()}), 'in_progress');
      expect(contractStageOf({'status': 'active', 'workStartedAt': Timestamp.now(), 'submissionCount': 1}), 'submitted');
    });
    test('a revision request puts it back in progress', () {
      expect(contractStageOf({'status': 'active', 'workStartedAt': Timestamp.now(), 'submissionCount': 1, 'revisionCount': 1}),
          'in_progress');
    });
    test('older contracts without a counter: a set submittedAt counts as one submission', () {
      final c = {'status': 'active', 'workStartedAt': Timestamp.now(), 'submittedAt': Timestamp.now()};
      expect(submissionsOf(c), 1);
      expect(contractStageOf(c), 'submitted');
    });
    test('closed contracts', () {
      for (final s in ['completed', 'cancelled', 'rejected']) {
        expect(contractStageOf({'status': s}), s);
      }
    });
  });

  group('commission (must equal the rules: 10%, whole rupees)', () {
    test('splits the price', () {
      final s = splitAmount(2500);
      expect(s.commission, 250);
      expect(s.earnings, 2250);
    });
    test('rounds to whole rupees', () {
      final s = splitAmount(1255);
      expect(s.commission, 126);
      expect(s.earnings, 1129);
    });
  });

  group('bad input is refused before anything is sent', () {
    final t = ContractTransactions(_NoDb(), 'w1');
    test('a submission note needs 10–1000 characters, and at most 3 photos', () {
      expect(() => t.submit('c', note: 'short'), _refused(ContractStepProblem.invalid));
      expect(() => t.submit('c', note: 'Replaced both sockets.', attachments: ['a', 'b', 'c', 'd']),
          _refused(ContractStepProblem.invalid));
    });
    test('cancelling needs a listed reason and a short note', () {
      expect(() => t.cancel('c', reason: 'spite'), _refused(ContractStepProblem.invalid));
      expect(() => t.cancel('c', reason: 'other', note: 'x' * 301), _refused(ContractStepProblem.invalid));
    });
    test('an address needs 5–200 characters and a real map position', () {
      expect(() => t.shareAddress('c', 'abc'), _refused(ContractStepProblem.invalid));
      expect(() => t.shareAddress('c', 'House 7, Street 3', lat: 0, lng: 0), _refused(ContractStepProblem.invalid));
      expect(() => t.shareAddress('c', 'House 7, Street 3', lat: 95, lng: 74), _refused(ContractStepProblem.invalid));
      expect(() => t.shareAddress('c', 'House 7, Street 3', lat: 31.5), _refused(ContractStepProblem.invalid));
    });
    test('a revision note needs 10–1000 characters', () {
      expect(() => t.requestRevision('c', note: 'redo'), _refused(ContractStepProblem.invalid));
    });
    test('a progress update needs a proper request id and 2–1000 characters', () {
      expect(() => t.progressUpdate('c', requestId: 'bad id!', note: 'On my way'), _refused(ContractStepProblem.invalid));
      expect(() => t.progressUpdate('c', requestId: 'req_00000001', note: 'x'), _refused(ContractStepProblem.invalid));
    });
    test('ids are required', () {
      expect(() => t.acceptProposal(''), _refused(ContractStepProblem.invalid));
      expect(() => t.respondToDirectRequest('', accept: true), _refused(ContractStepProblem.invalid));
    });
  });
}
