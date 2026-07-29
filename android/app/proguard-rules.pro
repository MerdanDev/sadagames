# R8 rules for the release build.
#
# The Flutter Gradle plugin already contributes rules for the engine and for any
# plugin that ships its own consumer rules, so this file only has to cover what
# those miss. Keep it empirical: add a rule when a build or a release run proves
# it is needed, and say which symptom it fixes.

# Nothing needed yet: a full R8 run over this app reported no missing classes and
# no warnings, so the rules Flutter and its plugins contribute already cover it.
