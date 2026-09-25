import '../../../../getxify.dart';

final Map<Transition, CustomTransition> _transitionStrategies = {
  Transition.leftToRight: SlideLeftTransition(),
  Transition.downToUp: SlideDownTransition(),
  Transition.upToDown: SlideTopTransition(),
  Transition.noTransition: NoTransition(),
  Transition.rightToLeft: SlideRightTransition(),
  Transition.zoom: ZoomInTransition(),
  Transition.fadeIn: FadeInTransition(),
  Transition.rightToLeftWithFade: RightToLeftFadeTransition(),
  Transition.leftToRightWithFade: LeftToRightFadeTransition(),
  Transition.size: SizeTransitions(),
  Transition.circularReveal: CircularRevealTransition(),
};

CustomTransition? getTransitionStrategy(Transition? transition) {
  if (transition == null) return null;
  return _transitionStrategies[transition];
}
