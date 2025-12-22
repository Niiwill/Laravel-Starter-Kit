<?php

namespace App\Auth;

use Illuminate\Contracts\Auth\Authenticatable;

class JwtUser implements Authenticatable
{
    public function __construct(
        public readonly string $id,
        public readonly ?string $email,
        public readonly array $roles
    ) {}

    public function getAuthIdentifierName() { return 'id'; }
    public function getAuthIdentifier() { return $this->id; }
    public function getAuthPasswordName() { return null; }
    public function getAuthPassword() { return null; }
    public function getRememberToken() { return null; }
    public function setRememberToken($value) {}
    public function getRememberTokenName() { return null; }


    public function hasRole(string $role): bool
    {
        return in_array($role, $this->roles, true);
    }
}
