-- Do this first in the postgresql instance

create DATABASE trustle;

create TABLE pokemons (
    Name VARCHAR(255),
    Pokedex_Number INTEGER PRIMARY KEY,
    Type1 VARCHAR(255),
    Type2 VARCHAR(255),
    Classification VARCHAR(255),
    Height_m FLOAT,
    Weight_kg FLOAT,
    Abilities VARCHAR(255),
    Generation INTEGER,
    Legendary_Status BOOLEAN
);
