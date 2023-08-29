import requests
import csv

def fetch_data_from_api():
    """
    Fetches data from the given API endpoint.

    Returns:
        list: A list of dictionaries containing university data.
    """
    url = "http://universities.hipolabs.com/search?country=Canada"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

def write_data_to_csv(data, filename="universities.csv"):
    """
    Writes the provided data to a CSV file.

    Args:
        data (list): List of dictionaries containing university data.
        filename (str, optional): Name of the CSV file to write. Defaults to "universities.csv".
    """
    with open(filename, 'w', newline='') as csv_file:
        fieldnames = ['name', 'country', 'website']  # Add any other fields as required
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        
        writer.writeheader()
        for university in data:
            writer.writerow({
                'name': university['name'],
                'country': university['country'],
                'website': university.get('website', 'N/A')
            })

def main():
    data = fetch_data_from_api()
    write_data_to_csv(data)

if __name__ == "__main__":
    main()
