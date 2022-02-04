extends Node;
class_name UtilityAI;

class Behavior:
	var name: String;
	var calculateUtility: Callable;
	var act: Callable;

	## The importance hierarchy ranking of the behavior. Only behaviors with a 
	## priorityLevel equal to or greater than the active Behavior will be
	## evaluated.
	var priorityLevel: int;

	func _init(name, calculateUtility, act, priorityLevel = 0):
		self.name = name;
		self.calculateUtility = calculateUtility;
		self.act = act;
		self.priorityLevel = priorityLevel;

var tickInterval = 1; # In seconds
var tickTimer = 0;

var behaviors = [];
var activeBehavior: Behavior;

func _ready():
	pass;

func _process(delta):
	tickTimer += delta;

	if(tickTimer > tickInterval):
		#@REVISIT architecture:
		## Run user defined callback:
		_tickMind();

		## Run internal callback:
		tickMind();

		tickTimer = 0;

func _tickMind():
	pass;

func addBehavior(behaviorName: String, calculateScore: Callable, act: Callable, priorityLevel = 0):
#	var priorityLevels.push(priorityLevel)

	var newBehavior = Behavior.new(behaviorName, calculateScore, act, priorityLevel);
	behaviors.push_back(newBehavior);

func tickMind():
	var priorityScores = contemplatePriorities();
	if(priorityScores.size()):
		var initializingBehavior = activeBehavior != priorityScores[0][1];
		if(initializingBehavior):
			activeBehavior = priorityScores[0][1];
			print('initializing behavior ' + activeBehavior.name);

		activeBehavior.act.call(initializingBehavior);

func contemplatePriorities():
	var priorityScores = [];

	for behavior in behaviors:
		var score = behavior.calculateUtility.call();
		priorityScores.push_back([score, behavior]);

	priorityScores.sort_custom(sort_scores_descending);
	return priorityScores;
	
#func addBehavior(
#	behaviorName: String,
#	calculateUtility: Callable,
#	act: Callable
#):
#	Behavior.new(behaviorName, calculateUtility, act);

static func sort_scores_descending(a, b):
	if a[0] > b[0]:
		return true
	return false
