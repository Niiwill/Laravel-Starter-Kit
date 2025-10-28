<?php

declare(strict_types=1);

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Index route for API
Route::get('/', function () {
    return response()->json(['message' => 'Welcome to the API!']);
});
