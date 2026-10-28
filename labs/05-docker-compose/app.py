import os

import psycopg
from flask import Flask, jsonify, request

app = Flask(__name__)


def get_conn():
    return psycopg.connect(
        host=os.environ.get("DB_HOST", "db"),
        dbname=os.environ.get("DB_NAME", "postgres"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ["DB_PASSWORD"],
        connect_timeout=3,
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/notes")
def list_notes():
    try:
        with get_conn() as conn:
            rows = conn.execute(
                "SELECT id, txt FROM notes ORDER BY id"
            ).fetchall()
        return jsonify([{"id": r[0], "txt": r[1]} for r in rows])
    except psycopg.Error:
        app.logger.exception("Database error while listing notes")
        return jsonify(error="Service temporarily unavailable"), 503


@app.post("/notes")
def add_note():
    txt = request.get_json(force=True).get("txt", "")
    try:
        with get_conn() as conn:
            conn.execute("INSERT INTO notes(txt) VALUES (%s)", (txt,))
        return jsonify(status="added"), 201
    except psycopg.Error:
        app.logger.exception("Database error while adding note")
        return jsonify(error="Service temporarily unavailable"), 503
