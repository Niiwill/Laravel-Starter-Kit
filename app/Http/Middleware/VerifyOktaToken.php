<?php

namespace App\Http\Middleware;

use Closure;
use App\Auth\JwtUser;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\JWK;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class VerifyOktaToken
{
    protected $oktaDomain;
    protected $audience;
    protected $issuer;

    public function __construct()
    {
        $this->oktaDomain = config('services.okta.domain');
        $this->audience = config('services.okta.audience');
        $this->issuer = config('services.okta.issuer');
    }

    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Get token from Authorization header
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => 'No token provided'
            ], 401);
        }

        try {
            // Fetch Okta's public keys
            // $jwks = $this->getOktaJWKS();
            
            // Decode and verify the token
            // $decoded = JWT::decode($token, JWK::parseKeySet($jwks));

            // Instead of decoding a real token
            $decoded = (object) [
                'sub' => '00u1dummyid',
                'name' => 'John Doe',
                'email' => 'john@example.com',
                'roles' => ['controllor'],
                'iat' => time(),
                'exp' => time() + 3600,
                'aud' => 'api://default',
                'iss' => 'https://dev-123456.okta.com/oauth2/default'
            ];

            // Verify issuer
            if ($decoded->iss !== $this->issuer) {
                throw new \Exception('Invalid issuer');
            }

            // Verify audience
            if (!in_array($this->audience, (array)$decoded->aud)) {
                throw new \Exception('Invalid audience');
            }

            // Verify expiration
            if ($decoded->exp < time()) {
                throw new \Exception('Token expired');
            }

            $user = new JwtUser(
                id: $decoded->sub,
                email: $decoded->email ?? null,
                roles: $decoded->roles ?? $decoded->groups ?? []
            );

            Auth::setUser($user);

            return $next($request);

        } catch (\Firebase\JWT\ExpiredException $e) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => 'Token has expired'
            ], 401);
        } catch (\Firebase\JWT\SignatureInvalidException $e) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => 'Invalid token signature'
            ], 401);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Unauthorized',
                'message' => $e->getMessage()
            ], 401);
        }
    }

    /**
     * Fetch JWKS from Okta
     */
    protected function getOktaJWKS(): array
    {
        $cacheKey = 'okta_jwks';
        
        // Cache the JWKS for 24 hours
        return cache()->remember($cacheKey, 86400, function () {
            $jwksUrl = "{$this->oktaDomain}";
            
            $response = Http::get($jwksUrl);
            
            if ($response->failed()) {
                throw new \Exception('Failed to fetch Okta JWKS');
            }
            
            return $response->json();
        });
    }
}
