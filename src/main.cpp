#include "../clips/core/clips.h"

int main() {
    Environment *env;

    env = CreateEnvironment();

    //Watch(env, STATISTICS);
    //Watch(env, FACTS);
    //Watch(env, ACTIVATIONS);
    if (Load(env,"clp/minesweeper.clp") != LoadError::LE_NO_ERROR)
        exit(1);
    Reset(env);
    //Facts(env, "stdout", NULL, -1, -1, -1);
    Run(env,-1);
    //Facts(env, "stdout", NULL, -1, -1, -1);

    DestroyEnvironment(env);
}

// Apakah KBS/CLIPS digunakan untuk semua fungsi program atau hanya untuk menentukan aksi (kotak mana yang akan dibuka), sementara untuk eksekusi aksi membuka kotak menggunakan program prosedural?
