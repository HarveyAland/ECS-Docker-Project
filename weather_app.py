import requests  # This is like telling Python, "I want to use a tool to ask for information from the internet."
from flask import Flask, render_template  # Telling Python that we are going to make a web app with Flask and show HTML pages.

app = Flask(__name__)  # This is creating a "Flask" app. Imagine it as a box where our web app lives.

API_KEY = 'd552c10073f57e64af138603e24430e7'  # This is like your secret password to access the weather data.
CITY = 'London'  # We want the weather for London.
BASE_URL = f'http://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric'  # This is the website we ask for the weather data.

#Health check
@app.route('/health') 
def health():
    return "OK", 200  # ALB will receive a 200 status, meaning the app is healthy.


@app.route('/') # This means "When someone goes to our website's home page, do the following."
def index():  # This is the function that runs when someone visits the page.
    response = requests.get(BASE_URL)  # We ask the weather website for the data.
    data = response.json()  # We take the data the website gives us and change it into a format we can use.

    # Check if everything went fine with the data
    if data["cod"] == 200:  # If the website says it's all good (code 200 means everything worked)
        temperature = data["main"]["temp"]  # We get the temperature from the data.
        description = data["weather"][0]["description"]  # We get the weather description (like "sunny" or "cloudy").
        city_name   = data["name"] # Extract the city name from the API response
    else:
        temperature = None  # If something went wrong, we say there's no temperature.
        description = "Error fetching data"  # We tell the user there was an error.

    return render_template('index.html', temperature=temperature, description=description, city=city_name)  # Show the webpage with the temperature and description.

app.run(host="0.0.0.0", port=5000, debug=True)