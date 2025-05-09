
#
from WebApp import db

from typing import List, Optional
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import ForeignKey
from sqlalchemy.types import String, Integer


class Course(db.Model):
### Write your solution here!
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    code: Mapped[str] = mapped_column(String(20), unique=True)
    students: Mapped[List["Student"]] = relationship("Student", back_populates="course")
###    


class Student(db.Model):
### Write your solution here!
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    neptun: Mapped[str] = mapped_column(String(6), unique=True)
    course_id: Mapped[int] = mapped_column(ForeignKey("course.id"))
    course: Mapped["Course"] = relationship("Course", back_populates="students")
###    
