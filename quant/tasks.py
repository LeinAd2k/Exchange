from celery import Celery

app = Celery('tasks', backend='redis://localhost:6379/11',
             broker='redis://localhost:6379/10')


@app.task
def add(x, y):
    return x + y
