from flask import render_template, flash, redirect, jsonify
from WebApp import app, db
from WebApp.forms.subscriptionForm import SubscriptionForm
from .models import Course, Student

@app.route('/')
@app.route('/index')
def index():
   courses = Course.query.all()
   return render_template("index.html", name="Moodle Lite", page="index", cnt=len(courses))

@app.route('/courses') 
def listItems():
   ### Write your solution here!
   courses = Course.query.all()
   ###
   return render_template("courses.html", name="Moodle Lite", courses=courses, page="courses")

@app.route('/subscription', methods=["GET", "POST"])
def order():
   ### Write your solution here!
   form = SubscriptionForm()
   if form.validate_on_submit():
       course = Course.query.filter_by(code=form.coursecode.data).first()
       if not course:
           flash(f'{form.coursecode.data} not found! Check the list!', 'error')
           return redirect('/courses')
       
       student = Student(
           name=form.name.data,
           neptun=form.neptun.data,
           course=course
       )
       db.session.add(student)
       try:
           db.session.commit()
           flash('You have successfully subscribed!', 'success')
           return redirect('/index')
       except:
           db.session.rollback()
           flash('Error occurred during subscription. Please try again.', 'error')
   ###
   return render_template('subscription.html', name='Moodle Lite', page="subscription", form=form)

### Write your solution here!
@app.route('/students/<course_code>')
def get_students(course_code):
   course = Course.query.filter_by(code=course_code).first()
   if not course:
       return jsonify({'error': 'Course not found'}), 404
   
   students = [{'name': student.name, 'neptun': student.neptun} for student in course.students]
   return jsonify(students)
###