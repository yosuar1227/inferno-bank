/**
 * @description Method to generate ramdomd amount
 * @returns Amount and Score generated
 */
export function generateRandomAmount() {
    // Generate a random number between 0 and 100 (inclusive)
    const score = Math.floor(Math.random() * 101);
    // Apply the formula
    const amount = 100 + (score / 100) * (10000000 - 100);
    // Return both values
    return { score, amount };
}