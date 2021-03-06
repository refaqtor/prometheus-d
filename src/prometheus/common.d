module prometheus.common;

import std.regex;
import prometheus.collectorRegistry;

public class IllegalArgumentException : Exception {
	this(string msg) {
		super(msg);
	}
}

mixin template BasicCollectorClassConstructor(T) {
	T name(string name) {
		this._name = name;
		return this;
	}

	T subsystem(string subsystem) {
		this._subsystem = subsystem;
		return this;
	}

	T namespace(string namespace) {
		this._namespace = namespace;
		return this;
	}

	T help(string help) {
		this._help = help;
		return this;
	}

	T labelNames(string[string] labels) {
		this._labels = labels;
		return this;
	}

	T create() {
		return new T();
	}
}

mixin template getSimpleTextExpositionTemplate() {
	override public string getTextExposition() {
		import prometheus.exposition.text;
		import std.format;
		import std.array;
		string[] text;
		text ~= HELP_LINE.format(_name, escape(_help));
		text ~= TYPE_LINE.format(_name, getType());
		text ~= METRIC_LINE.format(_name, getLabelsTextExposition(), value);

		return text.join(DELIMITER);
	}
}

public static immutable double NANOSECONDS_PER_SECOND = 1E9;
/**
* Number of milliseconds in a second.
*/
public static immutable double MILLISECONDS_PER_SECOND = 1E3;

/**
* Throw an exception if the metric name is invalid.
*/
static void checkMetricName(string name) {
	static auto METRIC_NAME_RE = ctRegex!"[a-zA-Z_:][a-zA-Z0-9_:]*";
	if (!name.match(METRIC_NAME_RE))
		throw new IllegalArgumentException("Invalid metric name: " ~ name);
}

/**
* Sanitize metric name
*/
public static string sanitizeMetricName(string metricName) {
	static auto SANITIZE_PREFIX_PATTERN = ctRegex!"^[^a-zA-Z_]";
	static auto SANITIZE_BODY_PATTERN = ctRegex!"[^a-zA-Z0-9_]";
	return metricName.replaceFirst(SANITIZE_PREFIX_PATTERN, "_")
		.replaceAll(SANITIZE_BODY_PATTERN, "_");
}


/**
* Sanitize label names
*/
public static checkLabelNames(string[string] labels) {
	foreach(label, value; labels)
		checkMetricLabelName(label);
}

/**
* Throw an exception if the metric label name is invalid.
*/
public static void checkMetricLabelName(string name) {
	static auto METRIC_LABEL_NAME_RE = ctRegex!"[a-zA-Z_][a-zA-Z0-9_]*";
	if (!name.match(METRIC_LABEL_NAME_RE))
		throw new IllegalArgumentException("Invalid metric label name: " ~ name);

	static auto RESERVED_METRIC_LABEL_NAME_RE = ctRegex!"__.*";
	if (!name.match(RESERVED_METRIC_LABEL_NAME_RE))
		throw new IllegalArgumentException("Invalid metric label name, reserved for internal use: " ~ name);
}

public static void checkHelp(string helpText) {
	if (!helpText.length)
		throw new IllegalArgumentException("Please provide a help text for all metrics");
}
