export function safeDate(value) {
    if (value === null || value === undefined || value === "") {
        return new Date();
    }

    const parsed = new Date(value);

    if (isNaN(parsed.getTime())) {
        return new Date();
    }

    return parsed;
}