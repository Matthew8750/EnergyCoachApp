import unittest

from ai import train_energy_model


class EnergyModelTests(unittest.TestCase):
    def test_filter_training_logs_ignores_blank_actual_energy(self):
        rows = [
            {"actualEnergy": "5"},
            {"actualEnergy": ""},
            {"actualEnergy": "   "},
        ]

        training_rows = train_energy_model.filter_training_logs(rows)

        self.assertEqual(len(training_rows), 1)
        self.assertEqual(training_rows[0]["actualEnergy"], "5")

    def test_latest_log_returns_newest_row(self):
        rows = [
            {"date": "First"},
            {"date": "Second"},
        ]

        self.assertEqual(train_energy_model.latest_log(rows)["date"], "Second")

    def test_training_logs_for_target_excludes_target_row(self):
        target = {"date": "Target", "actualEnergy": "6"}
        rows = [
            {"date": "Training", "actualEnergy": "5"},
            target,
            {"date": "Incomplete", "actualEnergy": ""},
        ]

        training_rows = train_energy_model.training_logs_for_target(rows, target)

        self.assertEqual(len(training_rows), 1)
        self.assertEqual(training_rows[0]["date"], "Training")

    def test_parse_bool_converts_true_and_false(self):
        self.assertEqual(train_energy_model.parse_bool("true"), 1.0)
        self.assertEqual(train_energy_model.parse_bool("false"), 0.0)

    def test_blank_feature_values_become_zero(self):
        row = {"steps": ""}

        self.assertEqual(train_energy_model.to_number(row, "steps"), 0.0)

    def test_distance_is_zero_for_identical_vectors(self):
        first_vector = [0.1, 0.5, 1.0]
        second_vector = [0.1, 0.5, 1.0]

        self.assertEqual(train_energy_model.distance(first_vector, second_vector), 0.0)

    def test_weighted_average_prediction_uses_similarity_weights(self):
        matches = [
            {"actual_energy": 8, "similarity": 1.0},
            {"actual_energy": 4, "similarity": 0.5},
        ]

        prediction = train_energy_model.weighted_average_prediction(matches)

        self.assertEqual(prediction, 6.7)

    def test_predict_actual_energy_returns_nearest_matches(self):
        logs = [
            make_log("Low day", sleep="5.5", stress="8", predicted="2", actual="3"),
            make_log("Good day", sleep="8.0", stress="3", predicted="9", actual="9"),
        ]
        new_day = make_example_day(sleep="8.1", stress="3", predicted="9")

        result = train_energy_model.predict_actual_energy(new_day, logs)

        self.assertEqual(result["matched_day"], "Good day")
        self.assertGreater(result["prediction"], 7.0)
        self.assertLess(result["prediction"], 9.0)
        self.assertEqual(len(result["matches"]), 2)


def make_log(name, sleep, stress, predicted, actual):
    return {
        "date": name,
        "sleepHours": sleep,
        "alcoholDrinks": "0",
        "lateCaffeine": "false",
        "mood": "7",
        "stress": stress,
        "restingHeartRate": "60",
        "hrv": "50",
        "steps": "8000",
        "workoutIntensity": "4",
        "predictedEnergy": predicted,
        "actualEnergy": actual,
    }


def make_example_day(sleep, stress, predicted):
    row = make_log("Example", sleep=sleep, stress=stress, predicted=predicted, actual="0")
    del row["date"]
    del row["actualEnergy"]
    return row


if __name__ == "__main__":
    unittest.main()
