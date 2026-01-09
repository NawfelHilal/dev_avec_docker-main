-- Script d'initialisation de la table students avec données de test
CREATE TABLE IF NOT EXISTS students
(
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100),
    promo VARCHAR(50),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertion des données de test
INSERT INTO students (nom, prenom, promo, email) VALUES
    ('Dupont', 'Jean', 'M2 Info', 'jean.dupont@ynov.com'),
    ('Martin', 'Marie', 'M2 Info', 'marie.martin@ynov.com'),
    ('Bernard', 'Pierre', 'M2 Info', 'pierre.bernard@ynov.com'),
    ('Durand', 'Sophie', 'M2 Info', 'sophie.durand@ynov.com'),
    ('Leroy', 'Thomas', 'M2 Info', 'thomas.leroy@ynov.com');
