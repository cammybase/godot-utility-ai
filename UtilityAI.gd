extends Node
class_name UtilityAI

## The amount of time between ticks of the mind.
var tickInterval = 1; # In seconds

## The amount of time that has passed since the last tick of the mind.
var delta_seconds = 0

## The behaviors that the mind can choose from.
var behaviors = []

## The behavior that is currently being performed.
var activeBehavior: Behavior; #@TODO probably pluralize and have behaviors that can be non-exclusive

func _ready():
	pass

func _process(deltaSeconds: float):
	delta_seconds += deltaSeconds

	if(delta_seconds > tickInterval):
		#@REVISIT architecture:
		## Run user defined callback:
		_tickMind(delta_seconds)

		## Run internal callback:
		tickMind(delta_seconds)

		delta_seconds = 0

func _tickMind(delta_seconds: float) -> void:
	pass

func tickMind(delta_seconds: float):
	var behavior_scores = contemplate_priorities(delta_seconds)

	if(behavior_scores.size()):
		# Whether we've found a behavior that consumes all attention: #@REVISIT architecture
		var fullyOccupied = false

		var priority = 0; #@RENAME to make clearer

		while(!fullyOccupied && priority < behavior_scores.size()):
			# If we did not run the behavior last frame #@REVISIT architecture
			var initializingBehavior: bool = (activeBehavior != behavior_scores[priority]["behavior"])
			if(initializingBehavior):
				# If had a behavior last tick and it has exit method, run it
				if(activeBehavior):
					if(activeBehavior.exit):
						activeBehavior.exit.call()

				# Set the new active behavior
				activeBehavior = behavior_scores[priority]["behavior"]

				# If the new behavior has an enter function, run it
				if(activeBehavior.enter):
					activeBehavior.enter.call()

			# Run the behavior's tick method
			var behaviorReturn = activeBehavior.tick.call(delta_seconds)

			# If behaviorReturn is an instance of BehaviorResult
			#@REVISIT should it not always be BehaviorResult
			if(behaviorReturn is BehaviorResult):
				# If the behavior wants to consume all attention
				fullyOccupied = behaviorReturn.exclusive

				# If the behavior wants to transition to another behavior
				if(behaviorReturn.transitionTo):
					activeBehavior = behaviorReturn.transitionTo

			# If behaviorReturn is not an instance of BehaviorResult
			else:
				# Assume behaviorReturn is a boolean representing fullyOccupied
				fullyOccupied = behaviorReturn

			priority += 1

#@TODO moving to this architecture
func add_behavior(behavior: Behavior):
	behaviors.push_back(behavior)

func contemplate_priorities(delta_seconds: float):
	var behavior_scores = []

	for behavior in behaviors:
		# Run the behavior's score function
		var score = behavior.score.call(delta_seconds)

		# Add score and behavior to the behavior_scores array
		behavior_scores.push_back({
			"score": score,
			"behavior": behavior
		})

	# Sort the behavior_scores array by score
	behavior_scores.sort_custom(sort_scores_descending)

	return behavior_scores

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
		self.priorityLevel = priorityLevel

class BehaviorResult:
	## Whether the behavior is exclusive and should consume all attention.
	var exclusive: bool

	## The behavior to transition to.
	var transitionTo: Behavior

	func _init(exclusive = false, transitionTo = null):
		self.exclusive = exclusive
		self.transitionTo = transitionTo

#@REVISIT architecture
static func NewBehaviorResult(params: Dictionary = {}):
	var exclusive = params.get("exclusive", true)
	var transitionTo = params.get("transitionTo", null)

	return BehaviorResult.new(exclusive, transitionTo)

