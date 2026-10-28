from unittest.mock import MagicMock, patch

import app


def test_health():
    client = app.app.test_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_list_notes():
    client = app.app.test_client()

    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn
    mock_conn.execute.return_value.fetchall.return_value = [
        (1, "First note"),
        (2, "Second note"),
    ]

    with patch("app.get_conn", return_value=mock_conn):
        response = client.get("/notes")

    assert response.status_code == 200
    assert response.get_json() == [
        {"id": 1, "txt": "First note"},
        {"id": 2, "txt": "Second note"},
    ]
    mock_conn.execute.assert_called_once_with(
        "SELECT id, txt FROM notes ORDER BY id"
    )


def test_add_note():
    client = app.app.test_client()

    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn

    with patch("app.get_conn", return_value=mock_conn):
        response = client.post("/notes", json={"txt": "Test note"})

    assert response.status_code == 201
    assert response.get_json() == {"status": "added"}
    mock_conn.execute.assert_called_once_with(
        "INSERT INTO notes(txt) VALUES (%s)",
        ("Test note",),
    )


def test_list_notes_database_error():
    client = app.app.test_client()

    with patch("app.get_conn", side_effect=app.psycopg.OperationalError("Database unavailable")):
        response = client.get("/notes")

    assert response.status_code == 503
    assert response.get_json() == {"error": "Service temporarily unavailable"}


def test_add_note_database_error():
    client = app.app.test_client()

    with patch(
        "app.get_conn",
        side_effect=app.psycopg.OperationalError("Database unavailable"),
    ):
        response = client.post("/notes", json={"txt": "Test note"})

    assert response.status_code == 503
    assert response.get_json() == {
        "error": "Service temporarily unavailable"
    }


def test_get_conn_uses_environment_configuration():
    with patch.dict(
        "os.environ",
        {
            "DB_HOST": "localhost",
            "DB_NAME": "notes_db",
            "DB_USER": "notes_user",
            "DB_PASSWORD": "test-password",
        },
    ), patch("app.psycopg.connect") as mock_connect:
        connection = app.get_conn()

    assert connection is mock_connect.return_value
    mock_connect.assert_called_once_with(
        host="localhost",
        dbname="notes_db",
        user="notes_user",
        password="test-password",
        connect_timeout=3,
    )
