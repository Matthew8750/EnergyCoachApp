import csv
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "energy_logs.csv"
EXAMPLE_CSV_PATH = PROJECT_ROOT / "energy_logs.example.csv"
NEIGHBOUR_COUNT = 3

FEATURE_COLUMNS = [
    "sleepHours",
    "alcoholDrinks",
    "lateCaffeine",
    "mood",
    "stress",
    "restingHeartRate",
    "hrv",
    "steps",
    "workoutIntensity",
    "predictedEnergy",
]


def load_logs():
    csv_path = choose_csv_path()

    with csv_path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def choose_csv_path():
    if CSV_PATH.exists():
        return CSV_PATH

    return EXAMPLE_CSV_PATH


def filter_training_logs(logs):
    return [
        row
        for row in logs
        if row.get("actualEnergy", "").strip()
    ]


def parse_bool(value):
    return 1.0 if value.lower() == "true" else 0.0


def to_number(row, column):
    value = row[column].strip()

    if value == "":
        return 0.0

    if column == "lateCaffeine":
        return parse_bool(value)

    return float(value)


def make_feature_vector(row):
    return [to_number(row, column) for column in FEATURE_COLUMNS]


def normalise_feature_vectors(vectors):
    columns = list(zip(*vectors))
    minimums = [min(column) for column in columns]
    maximums = [max(column) for column in columns]

    return [
        [
            normalise_value(value, minimums[index], maximums[index])
            for index, value in enumerate(vector)
        ]
        for vector in vectors
    ], minimums, maximums


def normalise_value(value, minimum, maximum):
    if maximum == minimum:
        return 0.0

    return (value - minimum) / (maximum - minimum)


def distance(first_vector, second_vector):
    squared_differences = [
        (first_value - second_value) ** 2
        for first_value, second_value in zip(first_vector, second_vector)
    ]

    return sum(squared_differences) ** 0.5


def predict_actual_energy(new_day, logs):
    training_vectors = [make_feature_vector(row) for row in logs]
    normalised_vectors, minimums, maximums = normalise_feature_vectors(training_vectors)

    new_vector = make_feature_vector(new_day)
    normalised_new_vector = [
        normalise_value(value, minimums[index], maximums[index])
        for index, value in enumerate(new_vector)
    ]

    distances = [
        distance(normalised_new_vector, vector)
        for vector in normalised_vectors
    ]
    nearest_matches = make_nearest_matches(
        logs,
        distances,
        min(NEIGHBOUR_COUNT, len(logs)),
    )
    prediction = weighted_average_prediction(nearest_matches)
    best_match = nearest_matches[0]

    return {
        "prediction": prediction,
        "matched_day": best_match["date"],
        "matched_predicted_energy": best_match["predicted_energy"],
        "similarity": best_match["similarity"],
        "matches": nearest_matches,
    }


def make_nearest_matches(logs, distances, count):
    ranked_indexes = sorted(range(len(distances)), key=lambda index: distances[index])
    nearest_indexes = ranked_indexes[:count]

    return [
        {
            "date": logs[index]["date"],
            "actual_energy": int(logs[index]["actualEnergy"]),
            "predicted_energy": int(logs[index]["predictedEnergy"]),
            "similarity": distance_to_similarity(distances[index], len(FEATURE_COLUMNS)),
            "distance": distances[index],
        }
        for index in nearest_indexes
    ]


def weighted_average_prediction(matches):
    weighted_total = 0.0
    weight_total = 0.0

    for match in matches:
        weight = max(match["similarity"], 0.01)
        weighted_total += match["actual_energy"] * weight
        weight_total += weight

    return round(weighted_total / weight_total, 1)


def average_swift_prediction_error(logs):
    if not logs:
        return None

    errors = [
        abs(float(row["predictedEnergy"]) - float(row["actualEnergy"]))
        for row in logs
    ]

    return sum(errors) / len(errors)


def print_data_summary(all_logs, training_logs):
    missing_actual_energy = len(all_logs) - len(training_logs)
    average_error = average_swift_prediction_error(training_logs)

    print("Data summary")
    print(f"- Total rows: {len(all_logs)}")
    print(f"- Completed rows: {len(training_logs)}")
    print(f"- Missing actual energy: {missing_actual_energy}")
    print(f"- AI method: {NEIGHBOUR_COUNT} nearest neighbours")

    if average_error is not None:
        print(f"- Average Swift prediction error: {average_error:.1f} energy points")


def distance_to_similarity(distance_value, feature_count):
    maximum_distance = feature_count ** 0.5
    similarity = 1.0 - (distance_value / maximum_distance)
    return max(0.0, min(1.0, similarity))


def make_example_days():
    return [
        {
            "name": "Tired but manageable",
            "sleepHours": "6.0",
            "alcoholDrinks": "1",
            "lateCaffeine": "true",
            "mood": "5",
            "stress": "7",
            "restingHeartRate": "72",
            "hrv": "32.0",
            "steps": "5000",
            "workoutIntensity": "3",
            "predictedEnergy": "4",
        },
        {
            "name": "Strong recovery",
            "sleepHours": "8.0",
            "alcoholDrinks": "0",
            "lateCaffeine": "false",
            "mood": "8",
            "stress": "3",
            "restingHeartRate": "58",
            "hrv": "60.0",
            "steps": "9000",
            "workoutIntensity": "4",
            "predictedEnergy": "9",
        },
        {
            "name": "Stress and low HRV",
            "sleepHours": "6.4",
            "alcoholDrinks": "0",
            "lateCaffeine": "true",
            "mood": "4",
            "stress": "9",
            "restingHeartRate": "79",
            "hrv": "27.0",
            "steps": "3000",
            "workoutIntensity": "1",
            "predictedEnergy": "4",
        },
        {
            "name": "After hard training",
            "sleepHours": "7.5",
            "alcoholDrinks": "0",
            "lateCaffeine": "false",
            "mood": "7",
            "stress": "4",
            "restingHeartRate": "66",
            "hrv": "45.0",
            "steps": "11000",
            "workoutIntensity": "9",
            "predictedEnergy": "8",
        },
    ]


def print_prediction_report(example_day, result):
    print(f"Example day: {example_day['name']}")
    print(f"Predicted actual energy: {result['prediction']}/10")
    print(f"Best matching logged day: {result['matched_day']}")
    print(f"Best match similarity: {result['similarity']:.0%}")
    print(f"Best match Swift prediction was: {result['matched_predicted_energy']}/10")
    print("")
    print("Nearest matches:")
    for match in result["matches"]:
        print(
            f"- {match['date']}: actual {match['actual_energy']}/10, "
            f"similarity {match['similarity']:.0%}"
        )
    print("")
    print("Inputs:")
    for column in FEATURE_COLUMNS:
        print(f"- {column}: {example_day[column]}")


def main():
    csv_path = choose_csv_path()
    all_logs = load_logs()
    logs = filter_training_logs(all_logs)
    example_days = make_example_days()

    print("Python AI prototype")
    print(f"Loaded data from {csv_path.name}")

    if csv_path == EXAMPLE_CSV_PATH:
        print("Using example data. Create energy_logs.csv for your private real data.")

    print_data_summary(all_logs, logs)
    print("")

    if len(logs) < 2:
        print("Not enough completed logs yet. Add actualEnergy ratings to at least 2 rows.")
        return

    for index, example_day in enumerate(example_days):
        result = predict_actual_energy(example_day, logs)
        print_prediction_report(example_day, result)

        if index < len(example_days) - 1:
            print("----------------------------------------")
            print("")


if __name__ == "__main__":
    main()
