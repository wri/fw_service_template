from fastapi import FastAPI

app = FastAPI()

@app.get("/template")
def root():
    return {"message": "Hello World from Forest Watcher Template Service!"}