extends Node;
class_name UtilityAI;

## The amount of time between ticks of the mind.
var tickInterval = 1; # In seconds

## The amount of time that has passed since the last tick of the mind.
var tickDeltaSeconds = 0;

## The behaviors that the mind can choose from.
var behaviors = [];

## The behavior that is currently being performed.
var activeBehavior: Behavior; #@TODO probably pluralize and have behaviors that can be non-exclusive

func _ready():
	pass;

func _process(deltaSeconds):
	tickDeltaSeconds += deltaSeconds;

	if(tickDeltaSeconds > tickInterval):
		#@REVISIT architecture:
		## Run user defined callback:
		_tickMind(tickDeltaSeconds);

		## Run internal callback:
		tickMind(tickDeltaSeconds);

		tickDeltaSeconds = 0;

func _tickMind(tickDeltaSeconds: float) -> void:
	pass;

func tickMind(tickDeltaSeconds):
	var priorityScores = contemplatePriorities();
	if(priorityScores.size()):
		# Whether we've found a behavior that consumes all attention: #@REVISIT architecture
		var fullyOccupied = false;

		var priority = 0; #@RENAME to make clearer

		while(!fullyOccupied && priority < priorityScores.size()):
			# If we did not run the behavior last frame #@REVISIT architecture
			var initializingBehavior: bool = (activeBehavior != priorityScores[priority]["behavior"]);
			if(initializingBehavior):
				# If had a behavior last tick and it has exit method, run it
				if(activeBehavior):
					if(activeBehavior.exit):
						activeBehavior.exit.call();

				# Set the new active behavior
				activeBehavior = priorityScores[priority]["behavior"];

				# If the new behavior has an enter function, run it
				if(activeBehavior.enter):
					activeBehavior.enter.call();

			# Run the behavior's tick method
			var behaviorReturn = activeBehavior.tick.call(tickDeltaSeconds);

			# If behaviorReturn is an instance of BehaviorResult
			#@REVISIT should it not always be BehaviorResult
			if(behaviorReturn is BehaviorResult):
				# If the behavior wants to consume all attention
				fullyOccupied = behaviorReturn.exclusive;

				# If the behavior wants to transition to another behavior
				if(behaviorReturn.transitionTo):
					activeBehavior = behaviorReturn.transitionTo;

			# If behaviorReturn is not an instance of BehaviorResult
			else:
				# Assume behaviorReturn is a boolean representing fullyOccupied
				fullyOccupied = behaviorReturn;

			priority += 1;

#@TODO moving to this architecture
func add_behavior(behavior: Behavior):
	behaviors.push_back(behavior);

func contemplatePriorities():
	var priorityScores = []

	for behavior in behaviors:
		var score = behavior.score.call()
		priorityScores.push_back({
			"score": score,
			"behavior": behavior
		})

	priorityScores.sort_custom(sort_scores_descending)
	return priorityScores

static func sort_scores_descending(a, b):
	if a["score"] > b["score"]:
		return true

	return false

class Behavior:
	var name: String

	## Called when the behavior is first activated
	var enter: Callable

	## Called every tick of the mind
	var tick: Callable

	## Called when the behavior is deactivated
	var exit: Callable

	## A function that returns a float representing the utility of the behavior
	var score: Callable

	## The importance hierarchy ranking of the behavior. Only behaviors with a
	## priorityLevel equal to or greater than the active Behavior will be
	## evaluated.
	var priorityLevel: int

	func _init(
		name: String,
		score: Callable,
		tick: Callable,
		enter: Callable = Callable(), #@REVISIT can't pass null; I don't like this at all though
		exit: Callable = Callable(),
		priorityLevel = 0
	):
		self.name = name
		self.score = score
		self.tick = tick
		self.enter = enter
		self.exit = exit
		self.priorityLevel = priorityLevel;

class BehaviorResult:
	## Whether the behavior is exclusive and should consume all attention.
	var exclusive: bool;

	## The behavior to transition to.
	var transitionTo: Behavior;

	func _init(exclusive = false, transitionTo = null):
		self.exclusive = exclusive;
		self.transitionTo = transitionTo;

#@REVISIT architecture
static func NewBehaviorResult(params: Dictionary = {}):
	var exclusive = params.get("exclusive", true);
	var transitionTo = params.get("transitionTo", null);

	return BehaviorResult.new(exclusive, transitionTo);
