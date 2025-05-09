from flask import render_template, flash, redirect, jsonify
from WebApp import app, db
from WebApp.forms.subscriptionForm import SubscriptionForm
from .models import Course, Student


test_courses = [
        {'id': 1, "code" : "VEMISAB254ZF", 'name': 'Python programozas',   'students': [ 
                                                                    { "neptun" : "JJJJJJ", "name" : "John"},
                                                                    { "neptun" : "RRRRRR", "name" : "Robert"},
                                                                    { "neptun" : "MMMMMM", "name" : "Mary"}
                                                                ]},
        {'id': 2, "code" : "VEMISAB146AP",'name': 'Programozas alapjai',  'students': [ 
                                                                    { "neptun" : "KKKKKK", "name" : "Kevin"},
                                                                    { "neptun" : "WWWWWW", "name" : "William"},
                                                                    { "neptun" : "TTTTTT", "name" : "Thomas"}
                                                                ]},
        {'id': 3, "code" : "VEMISAB156GF",'name': 'Programozas I.',       'students': [
                                                                    { "neptun" : "BBBBBB", "name" : "Bob"}
                                                                ]} 
    ]


@app.route('/')
@app.route('/index')
def index():
    return render_template("index.html", name="Moodle Lite", page = "index", cnt = len(test_courses))


#teszt adattal
"""@app.route('/courses')
def listItems():



    return render_template("courses.html", name="Moodle Lite", courses=test_courses, page = "courses" )"""

#adatbázissal
@app.route('/courses')
def listItems():

    courses = Course.query.all();

    return render_template("courses.html", name="Moodle Lite", courses=courses, page= "courses") #courses=test_courses, page = "courses" )
    
# teszt adattal
"""@app.route('/subscription', methods=["GET", "POST"])
def order():
    form = SubscriptionForm()
    if form.validate_on_submit:
        course_found = False
        for course in test_courses: #itrálunk a kurzusokon
            if course["code"] == form.coursecode.data: #ha létezik a kurus
                course["students"].append({"neptun": form.neptun.data, "name": form.name.data}) #uj student hozzáadása
                course_found = True
                flash("You have successfully subscribed!")
                return redirect("/index")
        
        if not course_found:
            flash("Course with this code not exists!")
    ###
    return render_template('subscription.html', name='Moodle Lite',page="subscription", form=form)"""

# adatbázissal
@app.route('/subscription', methods=["GET", "POST"])
def order():
    form = SubscriptionForm()
    if form.validate_on_submit():
        course = Course.query.filter_by(code=form.coursecode.data).first()
        if not course:
            return redirect("/courses", "{form.coursecode.data} not found! Check the list")
        
        student = Student(name=form.name.data, neptun=form.neptun.data, course=course)
        db.session.add(student)

        try:
            db.session.commit()
            flash('You have successfully sibscribed!', 'success')
            return redirect('/index')
        except:
            db.session.rollback()
            flash("Error uccured!")

    return render_template('subscription.html', name='Moodle Lite',page="subscription", form=form)

### API
@app.route('/students/<course_code>')
def get_students(course_code):
    course = Course.query.filter_by(code=course_code).first()
    if not course:
        return jsonify({'error':'Course not found'}), 404
    
    students = [{'name': students.name, 'neptun': students.neptun} for students in course.students]
    return jsonify(students)
###