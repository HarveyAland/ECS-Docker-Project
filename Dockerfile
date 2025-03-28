# Use an official Python runtime as a base image
FROM python:3.8-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the current directory contents (your Flask app) into the container's working directory
COPY . /app

# Install the required dependencies inside the container
RUN pip install -r requirements.txt

# Expose port 5000 for the Flask app
EXPOSE 5000

# Command to run your app
CMD ["python", "weather_app.py"]