document.addEventListener('DOMContentLoaded', function() {
    const checkbox = document.getElementById('edit_contact');

    checkbox.addEventListener('change', function() {
        const url = new URL(window.location);

        if (this.checked) {
        url.searchParams.set('edit', 'true');
        } else {
        url.searchParams.delete('edit');
        }

        // Update the browser's URL without reloading the page
        window.history.replaceState({}, '', url);
    });
});