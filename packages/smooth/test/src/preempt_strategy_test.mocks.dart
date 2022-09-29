// Mocks generated by Mockito 5.3.2 from annotations
// in smooth/test/src/preempt_strategy_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mockito/mockito.dart' as _i1;
import 'package:smooth/src/preempt_strategy.dart' as _i3;
import 'package:smooth/src/simple_date_time.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeDuration_0 extends _i1.SmartFake implements Duration {
  _FakeDuration_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeDateTime_1 extends _i1.SmartFake implements DateTime {
  _FakeDateTime_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeSimpleDateTime_2 extends _i1.SmartFake
    implements _i2.SimpleDateTime {
  _FakeSimpleDateTime_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [PreemptStrategyDependency].
///
/// See the documentation for Mockito's code generation for more information.
class MockPreemptStrategyDependency extends _i1.Mock
    implements _i3.PreemptStrategyDependency {
  @override
  Duration get currentFrameTimeStamp => (super.noSuchMethod(
        Invocation.getter(#currentFrameTimeStamp),
        returnValue: _FakeDuration_0(
          this,
          Invocation.getter(#currentFrameTimeStamp),
        ),
        returnValueForMissingStub: _FakeDuration_0(
          this,
          Invocation.getter(#currentFrameTimeStamp),
        ),
      ) as Duration);
  @override
  DateTime get beginFrameDateTime => (super.noSuchMethod(
        Invocation.getter(#beginFrameDateTime),
        returnValue: _FakeDateTime_1(
          this,
          Invocation.getter(#beginFrameDateTime),
        ),
        returnValueForMissingStub: _FakeDateTime_1(
          this,
          Invocation.getter(#beginFrameDateTime),
        ),
      ) as DateTime);
  @override
  _i2.SimpleDateTime now() => (super.noSuchMethod(
        Invocation.method(
          #now,
          [],
        ),
        returnValue: _FakeSimpleDateTime_2(
          this,
          Invocation.method(
            #now,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeSimpleDateTime_2(
          this,
          Invocation.method(
            #now,
            [],
          ),
        ),
      ) as _i2.SimpleDateTime);
}