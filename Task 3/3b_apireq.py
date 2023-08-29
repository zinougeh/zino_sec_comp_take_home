import csv
import requests
import logging
import sys
import argparse

# Set up logging
logging.basicConfig(filename='script_log.log', filemode='a', level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())  # Also log to console

def read_csv(filename):
    """Read data from CSV file."""
    try:
        with open(filename, mode='r', encoding='utf-8-sig') as file:  # Handle UTF-8 BOM
            reader = csv.DictReader(file)
            
            logging.debug(f"Detected columns in CSV: {reader.fieldnames}")
            
            if 'id' not in [field.strip().lower() for field in reader.fieldnames]:
                logging.error("The CSV does not contain an 'id' column.")
                sys.exit(1)
                
            data = [row for row in reader]
        logging.info(f"{len(data)} records read from {filename}")
        return data
    except Exception as e:
        logging.error(f"Error reading CSV: {e}")
        sys.exit(1)

def update_record(record):
    """Update a record using POST or PATCH."""
    endpoint = "https://reqres.in/api/users"
    try:
        record_id = record.get('id')
        if not record_id:
            logging.error(f"Missing 'id' for record: {record}")
            return

        response = requests.get(f"{endpoint}/{record_id}")

        # If the record does not exist, POST it.
        if response.status_code == 404:
            response = requests.post(endpoint, json=record)
            if response.status_code == 201:
                logging.info(f"Added record {record_id}.")
            else:
                logging.error(f"Error adding record {record_id} with status code {response.status_code}.")

        # If the record exists, PATCH it.
        elif response.status_code == 200:
            response = requests.patch(f"{endpoint}/{record_id}", json=record)
            if response.status_code == 200:
                logging.info(f"Updated record {record_id}.")
            else:
                logging.error(f"Error updating record {record_id} with status code {response.status_code}.")

        else:
            logging.warning(f"Unexpected status code {response.status_code} for record {record_id}.")

    except Exception as e:
        logging.error(f"API Error: {e}")

def main(filename):
    """Main function to process the CSV and update records."""
    records = read_csv(filename)
    
    for record in records:
        update_record(record)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a CSV file and update records via REST API.')
    parser.add_argument('csv_file', type=str, help='The path to the CSV file.')

    args = parser.parse_args()

    main(args.csv_file)
