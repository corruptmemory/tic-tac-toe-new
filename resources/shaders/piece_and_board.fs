#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 Normal;
in vec3 FragPos;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec3 lightPos;
uniform vec3 lightColor = vec3(1.0, 1.0, 1.0);

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

void main() {
	vec3 norm = normalize(Normal);
	vec3 lightDir = normalize(lightPos - FragPos);

	float diff = max(dot(norm, lightDir), 0.0);
	vec3 diffuse = diff * lightColor;

    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);

    // NOTE: Implement here your fragment shader code

    finalColor = texelColor*(colDiffuse+vec4(diffuse,0.0))*fragColor;
}

